# Seeles MCP 接入说明

这份文档说明当前项目里 `seeles-bridge` MCP 的作用和边界。

## 结论先说

当前接入方式是：

- 已在本地项目中提供一个可运行的 MCP server
- 重点服务于“为新宠物生成 Seeles 可直接投喂的样式 prompt”
- 读取项目内现有宠物队列和分支设定
- 输出结构化、可复用的宠物形象 brief

它不是：

- Seeles 官方公开 API 的直连封装
- 也不是 OpenAPI 自动生成的 MCP server

原因是目前没有确认到稳定公开的 Seeles 开发者文档或 OpenAPI 入口。

## 当前可用工具

`seeles-bridge` 暴露了这些工具：

- `compose_pet_style_brief`
  为单个宠物生成 Seeles prompt
- `compose_branch_style_brief`
  为整条进化线生成统一风格 prompt
- `list_pet_queue`
  读取当前项目的角色生成队列
- `list_supported_species`
  查看当前桥接器内置的物种与分支

## 推荐用法

先让 MCP 输出 prompt，再把 prompt 投喂给 Seeles 生成概念图或风格图。

推荐工作流：

1. 先用 `list_pet_queue` 看哪些宠物还是 `pending`
2. 对单个宠物调用 `compose_pet_style_brief`
3. 把输出 prompt 贴到 `https://www.seeles.ai/`
4. 产出满意后，再回到项目里替换素材或更新队列

## 示例

单宠物：

```text
tool: compose_pet_style_brief
arguments:
  species_id: "bubble"
  output_mode: "sprite prompt"
  extra_notes: "Keep the face extra readable at 16x16."
```

整条线：

```text
tool: compose_branch_style_brief
arguments:
  branch_id: "warm_light"
  focus: "flagship mascot refinement"
```

## 后续可扩展

如果后面你拿到 Seeles 的官方 API 文档、Token、或者私有接口约定，可以继续把这套桥接器升级成：

- 直接提交生成任务
- 轮询任务状态
- 下载生成结果
- 自动写回 `assets/pixellab/` 或新的素材目录

在那之前，当前版本更适合做“稳定的 prompt 生产层”。
