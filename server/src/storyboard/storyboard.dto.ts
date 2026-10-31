import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class CharacterDto {
  @IsString()
  @MinLength(1)
  @MaxLength(20)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  appearance?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  outfit?: string;
}

export class StoryboardRequestDto {
  @IsString()
  @MinLength(10)
  @MaxLength(3000)
  story!: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => CharacterDto)
  characters?: CharacterDto[];
}
