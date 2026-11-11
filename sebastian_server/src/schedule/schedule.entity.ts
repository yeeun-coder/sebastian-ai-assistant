import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  RelationId,
  Index,
} from 'typeorm';
import { User } from '../user/user.entity';
import { ScheduleDdayDateBasis } from './schedule-dday-date-basis.enum';

/** 데이터 출처 */
export const INPUT_SOURCE_AI = 'AI';
export const INPUT_SOURCE_MANUAL = '수동';

@Entity('schedule')
@Index('idx_schedule_user_start', ['user', 'startDate'])
export class Schedule {
  @PrimaryGeneratedColumn()
  id: number;

  /** FK: DB 컬럼 `user_id` */
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @RelationId((s: Schedule) => s.user)
  userId: number;

  @Column({ type: 'varchar', length: 500 })
  title: string;

  @Column({ type: 'text', nullable: true })
  content: string | null;

  /** AI 전용: 사용자 채팅 원문 */
  @Column({ type: 'text', nullable: true, name: 'original_text' })
  originalText: string | null;

  @Column({ type: 'datetime', name: 'start_date' })
  startDate: Date;

  @Column({ type: 'datetime', name: 'end_date' })
  endDate: Date;

  @CreateDateColumn({ type: 'datetime', name: 'created_at' })
  createdAt: Date;

  /** 식사, 회의, 복약 등 */
  @Column({ type: 'varchar', length: 100, nullable: true })
  category: string | null;

  /** 우선순위: 1=높음, 2=보통, 3=낮음 */
  @Column({ type: 'int', default: 2 })
  priority: number;

  /** 'AI' 또는 '수동' */
  @Column({ type: 'varchar', length: 20, name: 'input_source' })
  inputSource: string;

  @Column({ type: 'boolean', default: false, name: 'is_completed' })
  isCompleted: boolean;

  @Column({ type: 'datetime', nullable: true, name: 'completed_at' })
  completedAt: Date | null;

  @Column({ type: 'boolean', default: true, name: 'is_alarm_on' })
  isAlarmOn: boolean;

  @Column({ type: 'boolean', default: false, name: 'is_important' })
  isImportant: boolean;

  /** 일정 시작 몇 분 전에 알림 (1–10080, 기본 30) */
  @Column({
    type: 'smallint',
    name: 'notification_lead_minutes',
    default: 30,
  })
  notificationLeadMinutes: number;

  /** 일정 등록 시 함께 만든 D-Day (없으면 null) */
  @Column({ type: 'int', nullable: true, name: 'dday_id' })
  ddayId: number | null;

  /** D-Day 목표일 기준: 시작일 / 종료일 */
  @Column({
    type: 'varchar',
    length: 10,
    nullable: true,
    name: 'dday_date_basis',
  })
  ddayDateBasis: ScheduleDdayDateBasis | null;
}
