import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../user/user.entity';

@Entity('chat_messages')
export class ChatMessages {
  @PrimaryGeneratedColumn()
  id: number;

  //채팅을 보낸 사용자
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  //채팅을 보낸 사용자 아이디
  @Column()
  userId: number;

  //채팅을 보낸 게 누구인지 AI인지 사용자인지 구분
  @Column({ type: 'varchar', length: 20 })
  senderRole: string;

  @Column({ type: 'text' })
  message: string;

  @CreateDateColumn({ type: 'datetime' })
  createdAt: Date;
}
