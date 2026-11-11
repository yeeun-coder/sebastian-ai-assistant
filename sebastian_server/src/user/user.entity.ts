import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Persona } from '../chat/persona.entity';

@Entity('users')
export class User {
  
  @PrimaryGeneratedColumn()
  id: number;

  //중복불가
  @Column({ unique: true })
  email: string;

  //비밀번호 해시
  @Column()
  password: string;

  @Column({ length: 100 })
  nickname: string;

  @Column({ type: 'date' })
  birthDate: string;

  @Column({ default: '남' })
  gender: '남' | '여';

  @Column({ type: 'varchar', length: 500, nullable: true })
  profileImage: string | null;

  //현재 사용중인 persona
  @ManyToOne(() => Persona, { nullable: true })
  @JoinColumn({ name: 'activePersonaId' })
  activePersona: Persona | null;

  //현재 사용중인 persona 닉네임
  @Column({ type: 'varchar', length: 100, nullable: true })
  personaNickname: string | null;

  //가입일시 -> 자동생성
  @CreateDateColumn({ type: 'datetime' })
  createdAt: Date;

  // 태그명 예: "미루는 경향", "감정적", "분석적"
  @Column({ type: 'simple-array', nullable: true })
  tags: string[];
}
