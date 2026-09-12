# 参考图登记
实际图片取得后再加入manifest.json，记录id、path、sha256、role、rights_status与approval。
路径相对仓库根；不记录无法读取的opaque图像ID，不捆绑字体，不猜测旧会话图像路径。
rights_status使用cleared/unknown/restricted；公开release仅允许引用cleared素材。
approval为proposed/approved；后者必须有真实批准记录。只有proposed时可探索，但不能称为已锁定基线。
