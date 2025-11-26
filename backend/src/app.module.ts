import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { HabitsModule } from './habits/habits.module';
import { Habit } from './habits/entities/habit.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'sqlite',
      database: 'db.sqlite',
      entities: [Habit],
      synchronize: true, // Auto-create tables (dev only)
    }),
    HabitsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
