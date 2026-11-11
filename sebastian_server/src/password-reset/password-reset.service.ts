import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PasswordResetRequest,
  PasswordResetRequestStatus,
} from './password-reset-request.entity';
import { UsersService } from '../user/users.service';

export interface PasswordResetRequestView {
  id: number;
  email: string;
  status: PasswordResetRequestStatus;
  createdAt: Date;
  resolvedAt: Date | null;
  resolvedBy: string | null;
  memo: string | null;
  userId: number | null;
  nickname: string | null;
}

@Injectable()
export class PasswordResetService {
  constructor(
    @InjectRepository(PasswordResetRequest)
    private readonly repo: Repository<PasswordResetRequest>,
    private readonly usersService: UsersService,
  ) {}

  // 앱: 비밀번호 초기화 요청 접수
  // 이메일 존재 여부와 무관하게 동일 응답을 반환해 사용자 열람을 방지한다.
  async createRequest(email: string): Promise<void> {
    const normalized = email.trim().toLowerCase();

    // 동일 이메일에 대한 pending 요청이 이미 있으면 추가로 만들지 않는다.
    const existing = await this.repo.findOne({
      where: { email: normalized, status: 'pending' },
    });
    if (existing) return;

    const entity = this.repo.create({
      email: normalized,
      status: 'pending',
    });
    await this.repo.save(entity);
  }

  async list(
    status?: PasswordResetRequestStatus,
  ): Promise<PasswordResetRequestView[]> {
    const rows = await this.repo.find({
      where: status ? { status } : {},
      order: { createdAt: 'DESC' },
    });

    return Promise.all(rows.map((row) => this.toView(row)));
  }

  async countPending(): Promise<number> {
    return this.repo.count({ where: { status: 'pending' } });
  }

  async resolve(
    id: number,
    newPassword: string,
    resolvedBy: string,
    memo?: string,
  ): Promise<PasswordResetRequestView> {
    const request = await this.findPending(id);

    const user = await this.usersService.findByEmail(request.email);
    if (!user) {
      throw new NotFoundException(
        '요청 이메일에 해당하는 사용자가 존재하지 않습니다.',
      );
    }

    await this.usersService.adminResetPassword(user.id, newPassword);

    request.status = 'done';
    request.resolvedAt = new Date();
    request.resolvedBy = resolvedBy;
    if (memo !== undefined) request.memo = memo;
    const saved = await this.repo.save(request);
    return this.toView(saved);
  }

  async reject(
    id: number,
    resolvedBy: string,
    memo?: string,
  ): Promise<PasswordResetRequestView> {
    const request = await this.findPending(id);
    request.status = 'rejected';
    request.resolvedAt = new Date();
    request.resolvedBy = resolvedBy;
    if (memo !== undefined) request.memo = memo;
    const saved = await this.repo.save(request);
    return this.toView(saved);
  }

  private async findPending(id: number): Promise<PasswordResetRequest> {
    const request = await this.repo.findOne({ where: { id } });
    if (!request) {
      throw new NotFoundException('요청을 찾을 수 없습니다.');
    }
    if (request.status !== 'pending') {
      throw new NotFoundException('이미 처리된 요청입니다.');
    }
    return request;
  }

  private async toView(
    row: PasswordResetRequest,
  ): Promise<PasswordResetRequestView> {
    const user = await this.usersService.findByEmail(row.email);
    return {
      id: row.id,
      email: row.email,
      status: row.status,
      createdAt: row.createdAt,
      resolvedAt: row.resolvedAt,
      resolvedBy: row.resolvedBy,
      memo: row.memo,
      userId: user?.id ?? null,
      nickname: user?.nickname ?? null,
    };
  }
}
