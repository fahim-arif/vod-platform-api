import { Module } from '@nestjs/common';
import { TitlesService } from './titles.service';
import { TitlesController } from './titles.controller';

@Module({
  controllers: [TitlesController],
  providers: [TitlesService],
})
export class TitlesModule {}
