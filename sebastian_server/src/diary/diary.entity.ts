import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  RelationId,
  Index,
} from 'typeorm';
import { User } from '../user/user.entity';

@Entity('diary')
@Index('idx_diary_user_date', ['user', 'diaryDate'])
export class Diary {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @RelationId((d: Diary) => d.user)
  userId: number;

  /** 기록 대상 날 (YYYY-MM-DD, 한국 달력) */
  @Column({ type: 'date', name: 'diary_date' })
  diaryDate: string;

  @Column({ type: 'varchar', length: 200, nullable: true })
  title: string | null;

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'varchar', length: 30, nullable: true })
  mood: string | null;

  @Column({ type: 'varchar', length: 20, name: 'input_source', default: 'MANUAL' })
  inputSource: 'AI' | 'MANUAL';

  @Column({ type: 'text', nullable: true, name: 'original_text' })
  originalText: string | null;

  @CreateDateColumn({ type: 'datetime', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'datetime', name: 'updated_at' })
  updatedAt: Date;
}
