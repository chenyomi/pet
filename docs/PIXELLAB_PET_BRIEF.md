# PixelLab 宠物设计投喂稿

这份文件已经按新的正式宠物方案重写。

使用方式：

1. 在 VS Code 中确认 `pixellab` MCP 已加载
2. 打开支持 MCP 的聊天 / Agent 面板
3. 直接复制下面的 prompt 发送给 PixelLab

## Prompt

```text
Use PixelLab to redesign the full creature roster for my Flutter digital pet game.

This is a retro handheld-style virtual pet game with cute pixel monsters.
Please act as the creature art director and create a unified, premium, memorable pixel-pet IP system for the whole project.

Core goals:
- retro handheld virtual pet vibe
- readable at 16x16 and 24x24 sprite sizes
- cute but premium
- strong mascot appeal
- low-noise silhouettes
- clear evolution continuity
- suitable for actual game sprite production
- avoid copying Digimon, Pokemon, Tamagotchi, or any existing IP

Creature stages:
- Egg
- Baby
- Rookie
- Champion
- Ultimate

Full creature roster:

Egg:
- 数码蛋

Warm light line:
- 晨团兽
- 曜耳兽
- 圣纹虎机兽
- 天轮圣兽

Flame line:
- 炭牙兽
- 炎爪兽
- 烬冠龙兽

Star dream line:
- 露星兽
- 星羽兽
- 极辉翼兽
- 星冕天龙兽

Forest line:
- 豆芽兽
- 果核兽
- 苔甲兽
- 森甲兽
- 古树守护兽

Night shadow line:
- 雾团兽
- 月角兽
- 影幕灵兽

Ocean line:
- 潮鳍兽
- 珊甲海兽

Thunder line:
- 电啾兽
- 霆虎机兽

Secret line:
- 密钥兽
- 断章兽
- 秘纹龙兽
- 零界圣纹兽

Branch identity:
- Warm light: small sun, holy tiger guardian, creamy gold, sacred wheel
- Flame: ember fang, fire claw, ash dragon, fast attack energy
- Star dream: dew star, feathered star beast, aurora wings, celestial dragon
- Forest: sprout bean, fruit seed, moss armor, ancient tree guardian
- Night shadow: mist spirit, moon horn, shadow curtain, eerie but cute
- Ocean: tide fin, coral armor, bubbles, sea-ruin feeling
- Thunder: lightning ears, thunder tiger, speed and sparks
- Secret: key spirit, broken pages, rune dragon, fractured holy seal

Important visual rules:
- every creature must be easy to identify at first glance
- every evolution line must keep a strong silhouette inheritance
- baby forms should be round and simple
- advanced forms can become sacred or legendary, but should not become visually noisy
- each line should have one clear species anchor

What I need from you:
1. one unified art direction for the whole game
2. branch-by-branch redesign guidance
3. silhouette description for every creature
4. palette suggestion for every creature
5. notable features for every creature
6. how each creature evolves visually from the previous stage
7. expression rules for:
   - idle
   - happy
   - battle
   - sleepy
   - sick
   - sad
8. palette and shading rules for the whole project
9. implementation notes for Flutter pixel rendering

Important:
- prioritize actual sprite readability over illustration detail
- keep shapes iconic and low-noise
- make the warm light line strong enough to become the face of the project
- preserve clear contrast between branches while keeping one shared world

Output format:
- overall art direction
- branch by branch redesign
- stage by stage creature breakdown
- palette and shading rules
- expression rules
- implementation notes
```

## 建议追问

如果第一轮结果不错，再继续追问这一段：

```text
Continue from the approved overall art direction.

Now expand the same visual language into production-ready sprite guidance.

For each creature:
- refine silhouette hierarchy
- refine palette count for 16x16 and 24x24 usage
- define the face rule
- define one strongest identifying feature
- describe what must stay consistent across all expressions

Keep the results practical for real sprite production in a Flutter virtual pet game.
```
