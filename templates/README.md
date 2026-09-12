# 模板使用

复制模板只是开始，所有空字段、not_run、pending都不是完成记录。
card.json是fool:09的结构示例；新卡修改ID/路径/序列以匹配目标，不用它覆盖220张现有卡。
claim模板添加到当前途径canon.json的claims数组；先取证再标verified。
cue模板放入当前卡cues，语义维度的carrier_ids反向引用它。
reference-asset的空路径不得登记到正式manifest，只有实际取得文件后才添加。
generation写入card的production.generation；保留真实原始图，并记录任何resize/upscale。
review复制到真实产物版本目录后逐项审图；Agent不能把模板自动改为pass/approved。

处理操作使用layout/crop/resize/upscale/composite/color_convert/retouch等可辨识名称，并在description记录实际步骤。原图较小却交付更大图时，不得省略尺寸变换或合成记录。
