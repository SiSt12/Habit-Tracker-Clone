import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Habit } from './entities/habit.entity';
import { CreateHabitDto } from './dto/create-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';

@Injectable()
export class HabitsService {
    constructor(
        @InjectRepository(Habit)
        private habitsRepository: Repository<Habit>,
    ) { }

    findAll(): Promise<Habit[]> {
        return this.habitsRepository.find({
            order: { createdAt: 'ASC' },
        });
    }

    create(createHabitDto: CreateHabitDto): Promise<Habit> {
        const habit = this.habitsRepository.create(createHabitDto);
        return this.habitsRepository.save(habit);
    }

    async update(id: string, updateHabitDto: UpdateHabitDto): Promise<Habit> {
        const habit = await this.habitsRepository.preload({
            id: id,
            ...updateHabitDto,
        });
        if (!habit) {
            throw new NotFoundException(`Habit #${id} not found`);
        }
        return this.habitsRepository.save(habit);
    }

    async remove(id: string): Promise<void> {
        const habit = await this.findOne(id);
        await this.habitsRepository.remove(habit);
    }

    async findOne(id: string): Promise<Habit> {
        const habit = await this.habitsRepository.findOneBy({ id });
        if (!habit) {
            throw new NotFoundException(`Habit #${id} not found`);
        }
        return habit;
    }

    async updateHistory(id: string, history: Record<string, boolean>): Promise<Habit> {
        const habit = await this.findOne(id);
        habit.history = history;
        return this.habitsRepository.save(habit);
    }

    async toggleArchive(id: string): Promise<Habit> {
        const habit = await this.findOne(id);
        habit.archived = !habit.archived;
        return this.habitsRepository.save(habit);
    }
}
