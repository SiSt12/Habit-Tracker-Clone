import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity()
export class Habit {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;

    @Column()
    icon: string;

    @Column()
    color: number;

    @Column('simple-json', { default: '{}' })
    history: Record<string, boolean>;

    @Column({ default: false })
    archived: boolean;

    @CreateDateColumn()
    createdAt: Date;
}
