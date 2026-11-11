import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DDay } from './dday.entity';
import { DDayService } from './dday.service';
import { DDayController } from './dday.controller';

@Module({
  imports: [TypeOrmModule.forFeature([DDay])],
  controllers: [DDayController],
  providers: [DDayService],
  exports: [DDayService],
})
export class DDayModule {}
