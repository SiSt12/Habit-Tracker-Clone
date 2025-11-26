import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Habit Tracker API is running. Access the frontend at http://localhost:3001';
  }
}
