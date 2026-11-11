import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  JoinColumn,
  RelationId,
  Index,
} from 'typeorm';
import { User } from '../user/user.entity';
import { RoutineRepeatInterval } from './routine-repeat-interval.enum';

@Entity('routine')
@Index('idx_routine_user', ['user'])
export class Routine {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @RelationId((r: Routine) => r.user)
  userId: number;

  /** 루틴 폴더명 (예: 영양제 복용) */
  @Column({ type: 'varchar', length: 200 })
  category: string;

  @Column({ type: 'varchar', length: 500 })
  title: string;

  @Column({ type: 'varchar', name: 'target_time' })
  targetTime: string;

  @Column({
    type: 'varchar',
    length: 20,
    default: RoutineRepeatInterval.WEEKLY,
    name: 'repeat_interval',
  })
  repeatInterval: RoutineRepeatInterval;

  /** WEEKLY/BIWEEKLY: MON,TUE,... 쉼표 구분. 그 외 빈 문자열 */
  @Column({ type: 'varchar', name: 'repeat_days', default: '' })
  repeatDays: string;

  /** MONTHLY·YEARLY: 매월 같은 그날 (1–31) */
  @Column({ type: 'smallint', nullable: true, name: 'repeat_day_of_month' })
  repeatDayOfMonth: number | null;

  /** YEARLY: 월 (1–12) */
  @Column({ type: 'smallint', nullable: true, name: 'repeat_month' })
  repeatMonth: number | null;

  /** BIWEEKLY: 격주 기준일 YYYY-MM-DD */
  @Column({
    type: 'varchar',
    length: 10,
    nullable: true,
    name: 'biweekly_anchor_date',
  })
  biweeklyAnchorDate: string | null;

  @Column({ type: 'boolean', default: true, name: 'is_active' })
  isActive: boolean;
}
