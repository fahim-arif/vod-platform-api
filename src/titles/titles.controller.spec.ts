import { Test, TestingModule } from '@nestjs/testing';
import { TitlesController } from './titles.controller';
import { TitlesService } from './titles.service';

describe('TitlesController', () => {
  let controller: TitlesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TitlesController],
      providers: [TitlesService],
    }).compile();

    controller = module.get<TitlesController>(TitlesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
