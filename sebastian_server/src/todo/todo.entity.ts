import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../user/user.entity';

@Entity('todos')
export class Todo {

  @PrimaryGeneratedColumn()
  id: number;

  // 할 일을 등록한 사용자
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  // 사용자 아이디 (FK)
  @Column()
  userId: number;

  // 할 일 제목
  @Column({ type: 'varchar', length: 255 })
  title: string;

  // 상세 내용 (설명)
  @Column({ type: 'text', nullable: true })
  content: string | null;

  // 우선순위 (1: 높음, 2: 보통, 3: 낮음)
  @Column({ type: 'integer', default: 2 })
  priority: number;

  // 카테고리 (건강, 공부, 업무 등)
  @Column({ type: 'varchar', length: 100, nullable: true })
  category: string | null;

  // 입력 출처 ('AI' / 'MANUAL')
  @Column({ name: 'input_source', type: 'varchar', length: 20, default: 'MANUAL' })
  inputSource: 'AI' | 'MANUAL';

  // AI 입력 시 원문 (수동 입력 시 null)
  @Column({ name: 'original_text', type: 'text', nullable: true })
  originalText: string | null;

  // 완료 여부
  @Column({ default: false })
  isDone: boolean;

  // 실제 완료 일시
  @Column({ name: 'completed_at', type: 'datetime', nullable: true })
  completedAt: Date | null;

  // 마감일 (선택사항)
  @Column({ type: 'date', nullable: true })
  dueDate: string | null;

  /**
   * 마감일 기준 며칠 전부터 일정(캘린더)에 띄울지.
   * 0이면 선행 표시 없음(미선택·당일만 등 클라이언트 정책에 맡김), 3이면 마감 3일 전부터 표시.
   */
  @Column({ type: 'integer', default: 0 })
  scheduleLeadDays: number;

  // 등록일시 -> 자동생성
  @CreateDateColumn({ type: 'datetime' })
  createdAt: Date;
}
