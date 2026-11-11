import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';

export type PasswordResetRequestStatus = 'pending' | 'done' | 'rejected';

@Entity('password_reset_requests')
export class PasswordResetRequest {
  @PrimaryGeneratedColumn()
  id: number;

  @Index()
  @Column()
  email: string;

  @Index()
  @Column({ type: 'varchar', length: 16, default: 'pending' })
  status: PasswordResetRequestStatus;

  @CreateDateColumn({ type: 'datetime' })
  createdAt: Date;

  @Column({ type: 'datetime', nullable: true })
  resolvedAt: Date | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  resolvedBy: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  memo: string | null;
}
