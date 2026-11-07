import { ArrayMaxSize, ArrayMinSize, IsArray, IsString, MaxLength, MinLength } from 'class-validator';

/** 一批要画的道具名。客户端已归一化（去空白、全角转半角）。 */
export class DrawPropsRequestDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(5)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(10, { each: true })
  names!: string[];
}
