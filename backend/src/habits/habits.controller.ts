import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { HabitsService } from './habits.service';
import { CreateHabitDto } from './dto/create-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';

@Controller('habits')
export class HabitsController {
    constructor(private readonly habitsService: HabitsService) { }

    @Post()
    create(@Body() createHabitDto: CreateHabitDto) {
        return this.habitsService.create(createHabitDto);
    }

    @Get()
    findAll() {
        return this.habitsService.findAll();
    }

    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.habitsService.findOne(id);
    }

    @Patch(':id')
    update(@Param('id') id: string, @Body() updateHabitDto: UpdateHabitDto) {
        return this.habitsService.update(id, updateHabitDto);
    }

    @Delete(':id')
    remove(@Param('id') id: string) {
        return this.habitsService.remove(id);
    }

    @Patch(':id/history')
    updateHistory(@Param('id') id: string, @Body() body: { history: Record<string, boolean> }) {
        return this.habitsService.updateHistory(id, body.history);
    }

    @Patch(':id/archive')
    toggleArchive(@Param('id') id: string) {
        return this.habitsService.toggleArchive(id);
    }
}
