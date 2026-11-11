import {
    Entity,
    Column,
    PrimaryGeneratedColumn,
    CreateDateColumn,
} from 'typeorm';

@Entity('persona')
export class Persona {
    
    @PrimaryGeneratedColumn()
    id: number;

    //persona 종류
    @Column()
    type: string;
    
    //persona 이름 (신하, 엄마, 교관, 신사)
    @Column()
    name: string;

    //persona 속성(설정값)
    @Column()
    system_prompt: string;

    //persona 설명
    @Column()
    description: string;

    //persona 이미지
    @Column()
    image: string;
}