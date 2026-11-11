import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  ManyToOne,
  JoinColumn,
  RelationId,
  Index,
  Unique,
} from 'typeorm';
import { User } from '../user/user.entity';
import { Routine } from './routine.entity';

@Entity('routine_completion')
@Unique('uq_routine_completion_routine_date', ['routine', 'completedDate'])
@Index('idx_routine_completion_user_date', ['user', 'completedDate'])
export class RoutineCompletion {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => Routine, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'routine_id' })
  routine: Routine;

  @RelationId((c: RoutineCompletion) => c.routine)
  routineId: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @RelationId((c: RoutineCompletion) => c.user)
  userId: number;

  @Column({ type: 'varchar', length: 10, name: 'completed_date' })
  completedDate: string;
}
