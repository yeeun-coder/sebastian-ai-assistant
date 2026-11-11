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
import { DDayCountMode } from './dday-count-mode.enum';

@Entity('dday')
@Index('idx_dday_user', ['user'])
export class DDay {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @RelationId((d: DDay) => d.user)
  userId: number;

  @Column({ type: 'varchar', length: 200 })
  title: string;

  @Column({ type: 'date', name: 'target_date' })
  targetDate: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  category: string | null;

  @Column({ type: 'text', nullable: true })
  memo: string | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  color: string | null;

  @Column({ type: 'boolean', default: false, name: 'is_pinned' })
  isPinned: boolean;

  @Column({
    type: 'varchar',
    length: 10,
    default: DDayCountMode.DOWN,
    name: 'count_mode',
  })
  countMode: DDayCountMode;

  @Column({ type: 'varchar', length: 20, name: 'input_source', default: 'MANUAL' })
  inputSource: 'AI' | 'MANUAL';

  @Column({ type: 'text', nullable: true, name: 'original_text' })
  originalText: string | null;

  @CreateDateColumn({ type: 'datetime', name: 'created_at' })
  createdAt: Date;
}
