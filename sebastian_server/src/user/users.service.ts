import { ConflictException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { Persona } from '../chat/persona.entity';
import bcrypt from 'bcrypt';
import { CreateUserDto } from './dto/create-user.dto';
import { UserProfileResponseDto } from './dto/user-profile-response.dto';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';

/** 가입 시 기본 활성 페르소나 (`persona.type`) */
const DEFAULT_PERSONA_TYPE = 'basic';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Persona)
    private personaRepository: Repository<Persona>,
  ) {}

  //회원가입
  async create(createUserDto: CreateUserDto): Promise<User> {
    const existingUser = await this.userRepository.findOne({ where: { email: createUserDto.email } });

    if (existingUser) {
      throw new ConflictException('이미 사용 중인 이메일입니다');
    }

    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);

    const user = this.userRepository.create({
      ...createUserDto,
      password: hashedPassword,
    });

    const savedUser = await this.userRepository.save(user);

    const basicPersona = await this.personaRepository.findOne({
      where: { type: DEFAULT_PERSONA_TYPE },
    });
    if (basicPersona) {
      savedUser.activePersona = basicPersona;
      await this.userRepository.save(savedUser);
    }

    return savedUser;
  }

  //이메일로 사용자 찾기
  async findByEmail(email: string): Promise<User | null> {
    return await this.userRepository.findOne({ where: { email } });
  }

  //사용자 찾기
  async findAll(): Promise<User[]> {
    return await this.userRepository.find();
  }

  async findOne(id: number): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }
    return user;
  }

  //비밀번호 변경
  async updatePassword(userId: number, currentPassword: string, newPassword: string): Promise<void> {
    const user = await this.findOne(userId);

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('현재 비밀번호가 올바르지 않습니다');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    Object.assign(user, { password: hashedPassword });
    await this.userRepository.save(user);
  }

  // 프로필 조회 (이름·나이·성별·태그)
  async getProfile(userId: number): Promise<UserProfileResponseDto> {
    const user = await this.findOne(userId);
    return this.toProfileResponse(user);
  }

  async updateProfile(
    userId: number,
    updateUserProfileDto: UpdateUserProfileDto,
  ): Promise<UserProfileResponseDto> {
    const user = await this.findOne(userId);
    const { age, ...profileFields } = updateUserProfileDto;

    if (profileFields.birthDate !== undefined) {
      user.birthDate = profileFields.birthDate;
    } else if (age !== undefined) {
      user.birthDate = this.birthDateFromAge(age);
    }

    if (profileFields.nickname !== undefined) {
      user.nickname = profileFields.nickname;
    }
    if (profileFields.gender !== undefined) {
      user.gender = profileFields.gender;
    }
    if (profileFields.profileImage !== undefined) {
      user.profileImage = profileFields.profileImage;
    }

    const updatedUser = await this.userRepository.save(user);
    return this.toProfileResponse(updatedUser);
  }

  async updateProfileImage(
    userId: number,
    imagePath: string,
  ): Promise<UserProfileResponseDto> {
    const user = await this.findOne(userId);
    user.profileImage = imagePath;
    const updatedUser = await this.userRepository.save(user);
    return this.toProfileResponse(updatedUser);
  }

  private toProfileResponse(user: User): UserProfileResponseDto {
    return {
      nickname: user.nickname,
      age: this.calculateAge(user.birthDate),
      birthDate: user.birthDate,
      gender: this.normalizeGender(user.gender),
      tags: user.tags ?? [],
      profileImage: user.profileImage ?? null,
    };
  }

  private birthDateFromAge(age: number): string {
    const year = new Date().getFullYear() - age;
    return `${year}-01-01`;
  }

  private normalizeGender(gender: string): '남' | '여' {
    if (gender === '여' || gender === 'female') return '여';
    return '남';
  }

  private calculateAge(birthDate: string): number {
    const birth = new Date(birthDate);
    const today = new Date();
    let age = today.getFullYear() - birth.getFullYear();
    const m = today.getMonth() - birth.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  }

  // 사용자 성향 태그 조회
  async getTags(userId: number): Promise<string[]> {
    const user = await this.findOne(userId);
    return user.tags ?? [];
  }
  // 사용자 성향 태그 업데이트 할때 5개 제한

  //사용자 삭제
  async remove(email: string): Promise<void> {
    const user = await this.findByEmail(email);
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }
    await this.userRepository.remove(user);
  }

  async adminListUsers(): Promise<
    Array<{
      id: number;
      email: string;
      nickname: string;
      birthDate: string;
      gender: string;
      createdAt: Date;
    }>
  > {
    const rows = await this.userRepository.find({
      order: { id: 'ASC' },
      select: {
        id: true,
        email: true,
        nickname: true,
        birthDate: true,
        gender: true,
        createdAt: true,
      },
    });
    return rows.map((u) => ({
      id: u.id,
      email: u.email,
      nickname: u.nickname,
      birthDate: u.birthDate,
      gender: u.gender,
      createdAt: u.createdAt,
    }));
  }

  async adminResetPassword(userId: number, newPassword: string): Promise<void> {
    const user = await this.findOne(userId);
    user.password = await bcrypt.hash(newPassword, 10);
    await this.userRepository.save(user);
  }

  async adminCreateUser(dto: CreateUserDto): Promise<{
    id: number;
    email: string;
    nickname: string;
    birthDate: string;
    gender: string;
    createdAt: Date;
  }> {
    const created = await this.create(dto);
    return {
      id: created.id,
      email: created.email,
      nickname: created.nickname,
      birthDate: created.birthDate,
      gender: created.gender,
      createdAt: created.createdAt,
    };
  }

  async adminUpdateUser(
    id: number,
    dto: Partial<Pick<User, 'email' | 'nickname' | 'birthDate' | 'gender'>>,
  ): Promise<{
    id: number;
    email: string;
    nickname: string;
    birthDate: string;
    gender: string;
    createdAt: Date;
  }> {
    const user = await this.findOne(id);

    if (dto.email && dto.email !== user.email) {
      const exists = await this.userRepository.findOne({
        where: { email: dto.email },
      });
      if (exists && exists.id !== id) {
        throw new ConflictException('이미 사용 중인 이메일입니다');
      }
    }

    Object.assign(user, dto);
    const saved = await this.userRepository.save(user);
    return {
      id: saved.id,
      email: saved.email,
      nickname: saved.nickname,
      birthDate: saved.birthDate,
      gender: saved.gender,
      createdAt: saved.createdAt,
    };
  }

  async adminDeleteUser(id: number): Promise<void> {
    const user = await this.findOne(id);
    await this.userRepository.remove(user);
  }
}