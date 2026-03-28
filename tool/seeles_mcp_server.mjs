#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const PROJECT_ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const QUEUE_PATH = path.join(PROJECT_ROOT, 'docs', 'PIXELLAB_CHARACTER_QUEUE_2026-03-25.md');

const STAGE_LABELS = {
  egg: 'Egg',
  baby: 'Baby',
  rookie: 'Rookie',
  champion: 'Champion',
  ultimate: 'Ultimate',
};

const BRANCHES = {
  warm_light: {
    label: '暖光系',
    keywords: ['dawn light', 'creamy gold', 'soft halo', 'guardian mascot'],
    contrast: '项目旗舰线，轮廓最干净、情绪最治愈、最适合做首页门面。',
    species: ['bubble', 'sunbit', 'thunder', 'halo'],
  },
  flame: {
    label: '烈焰系',
    keywords: ['ember', 'heat claw', 'magma markings', 'aggressive energy'],
    contrast: '攻击感最强，强调速度、火牙和尾焰，不走笨重火龙路线。',
    species: ['ember', 'flare', 'blaze'],
  },
  star_dream: {
    label: '星梦系',
    keywords: ['star dust', 'aurora', 'glass candy glow', 'elegant flight'],
    contrast: '更轻盈、更梦幻，依赖羽翼、拖尾和星点分布建立辨识度。',
    species: ['pearl', 'glint', 'aurora', 'nova'],
  },
  forest: {
    label: '森林系',
    keywords: ['moss', 'seed', 'bark shell', 'guardian statue'],
    contrast: '偏沉稳守护感，强调背芽、木壳和石甲，不走可怕巨兽路线。',
    species: ['mint', 'sprout', 'moss', 'bloom'],
  },
  night_shadow: {
    label: '夜影系',
    keywords: ['mist', 'moonlight', 'floating spirit', 'cold glow eyes'],
    contrast: '可爱但诡秘，靠漂浮轮廓、雾尾、断裂边缘和冷光眼建立氛围。',
    species: ['gloom', 'mist', 'dusk'],
  },
  ocean: {
    label: '深海系',
    keywords: ['tide', 'fins', 'coral', 'bubble relics'],
    contrast: '流线感更强，强调鳍、泡泡、海潮纹，不做写实海怪。',
    species: ['tidal', 'reef'],
  },
  thunder: {
    label: '雷鸣系',
    keywords: ['electricity', 'tiger energy', 'sparks', 'dash motion'],
    contrast: '速度最快，形体更尖锐，适合高对比黄蓝电弧点缀。',
    species: ['spark', 'thunder'],
  },
  secret: {
    label: '秘藏系',
    keywords: ['runes', 'cipher', 'sacred glitch', 'forbidden archive'],
    contrast: '隐藏线，重点是蓝白密文、裂片和不完整神圣感。',
    species: ['cipher', 'glitch', 'sigil', 'paradox'],
  },
};

const SPECIES = {
  egg: {
    id: 'egg',
    name: '数码蛋',
    stage: 'egg',
    branch: 'warm_light',
    silhouette: 'rounded digital egg with a slightly asymmetrical crack pattern',
    palette: ['cream', 'soft sky blue', 'warm gray'],
    features: ['clean shell spots', 'gentle shine', 'low-noise crack detail'],
  },
  bubble: {
    id: 'bubble',
    name: '泡泡团兽',
    stage: 'baby',
    branch: 'warm_light',
    silhouette: 'round mascot blob with tiny bell-like ears and stubby feet',
    palette: ['cream gold', 'peach glow', 'soft brown'],
    features: ['halo blush', 'simple face', 'one memorable forehead shine'],
  },
  sunbit: {
    id: 'sunbit',
    name: '晴光兽',
    stage: 'rookie',
    branch: 'warm_light',
    silhouette: 'small guardian cub with perked ears and a compact chest puff',
    palette: ['creamy gold', 'sun orange', 'warm white'],
    features: ['tiny wing motifs', 'brighter eye spark', 'clean chest emblem'],
  },
  thunder: {
    id: 'thunder',
    name: '雷角虎机兽',
    stage: 'champion',
    branch: 'warm_light',
    silhouette: 'athletic tiger guardian with one strong forehead horn and cloak-like mane',
    palette: ['royal gold', 'warm ivory', 'ember orange'],
    features: ['holy horn', 'ring-tail accent', 'battle-ready paws'],
  },
  halo: {
    id: 'halo',
    name: '圣环团兽',
    stage: 'ultimate',
    branch: 'warm_light',
    silhouette: 'sacred beast with floating ring halo and broad ceremonial wings',
    palette: ['radiant gold', 'sunset white', 'soft orange'],
    features: ['floating halo', 'guardian cape feathers', 'legendary face mark'],
  },
  ember: {
    id: 'ember',
    name: '赤鳞幼兽',
    stage: 'baby',
    branch: 'flame',
    silhouette: 'small lizard cub with oversized flame crest',
    palette: ['ember red', 'charcoal', 'hot orange'],
    features: ['flame tail', 'ash-tipped ears', 'bitey expression'],
  },
  flare: {
    id: 'flare',
    name: '焰翼兽',
    stage: 'rookie',
    branch: 'flame',
    silhouette: 'sleek fire beast with wing-like shoulder flames',
    palette: ['lava orange', 'deep red', 'smoke gray'],
    features: ['heat claws', 'cheek sparks', 'compact wings'],
  },
  blaze: {
    id: 'blaze',
    name: '炎冠龙兽',
    stage: 'ultimate',
    branch: 'flame',
    silhouette: 'regal fire dragon with a crown-like blaze above the brow',
    palette: ['molten orange', 'crimson', 'ash black'],
    features: ['royal fire crown', 'tail furnace', 'heated chest core'],
  },
  mint: {
    id: 'mint',
    name: '薄荷豆兽',
    stage: 'baby',
    branch: 'forest',
    silhouette: 'round seed creature with a fresh leaf sprout',
    palette: ['mint green', 'seed beige', 'dew blue'],
    features: ['leaf tuft', 'dew dot eyes', 'soft bean body'],
  },
  sprout: {
    id: 'sprout',
    name: '芽芽果兽',
    stage: 'baby',
    branch: 'forest',
    silhouette: 'fruit seedling with a split shell and upward sprout',
    palette: ['sap green', 'fruit cream', 'dew cyan'],
    features: ['seed shell cap', 'sprout antenna', 'cute sleepy face'],
  },
  moss: {
    id: 'moss',
    name: '青苔甲兽',
    stage: 'champion',
    branch: 'forest',
    silhouette: 'compact guardian beast wearing layered moss armor',
    palette: ['moss green', 'stone gray', 'bark brown'],
    features: ['bark plating', 'moss shoulder pads', 'guardian eyes'],
  },
  bloom: {
    id: 'bloom',
    name: '森芽守护兽',
    stage: 'ultimate',
    branch: 'forest',
    silhouette: 'tree guardian statue with blooming back crest',
    palette: ['ancient green', 'stone moss', 'wood brown'],
    features: ['totem posture', 'blooming back halo', 'calm face'],
  },
  pearl: {
    id: 'pearl',
    name: '星露兽',
    stage: 'baby',
    branch: 'star_dream',
    silhouette: 'tiny star blob with droplet-like wing buds',
    palette: ['pastel blue', 'pearl white', 'aurora pink'],
    features: ['glassy sparkle', 'dew-tail', 'dreamy expression'],
  },
  glint: {
    id: 'glint',
    name: '星羽兽',
    stage: 'rookie',
    branch: 'star_dream',
    silhouette: 'bird-like dream pet with a clear star crest and feather tail',
    palette: ['moon blue', 'pearl white', 'soft violet'],
    features: ['star crest', 'glint feathers', 'elegant eyes'],
  },
  aurora: {
    id: 'aurora',
    name: '极星翼兽',
    stage: 'champion',
    branch: 'star_dream',
    silhouette: 'sleek aurora flier with long ribbon wings',
    palette: ['aurora cyan', 'starlight white', 'pink glow'],
    features: ['ribbon wings', 'polar tail', 'radiant chest gem'],
  },
  nova: {
    id: 'nova',
    name: '星核龙兽',
    stage: 'ultimate',
    branch: 'star_dream',
    silhouette: 'celestial dragon with a floating star core around the chest',
    palette: ['deep night blue', 'starlight silver', 'aurora magenta'],
    features: ['star core', 'royal neck line', 'constellation tail'],
  },
  gloom: {
    id: 'gloom',
    name: '雾幽兽',
    stage: 'baby',
    branch: 'night_shadow',
    silhouette: 'small ghost puff with drifting mist hem',
    palette: ['mist gray', 'moon blue', 'soft purple-gray'],
    features: ['cold glow eyes', 'mist tail', 'eerie cute grin'],
  },
  mist: {
    id: 'mist',
    name: '夜角兽',
    stage: 'rookie',
    branch: 'night_shadow',
    silhouette: 'floating horned spirit with a torn-cloak lower body',
    palette: ['night blue', 'fog gray', 'icy cyan'],
    features: ['moon horn', 'hover pose', 'sharp sleepy eyes'],
  },
  dusk: {
    id: 'dusk',
    name: '影幕灵兽',
    stage: 'ultimate',
    branch: 'night_shadow',
    silhouette: 'majestic phantom draped in a shadow curtain',
    palette: ['deep indigo', 'spectral cyan', 'cold silver'],
    features: ['shadow veil', 'broken moon ornaments', 'cold crown'],
  },
  tidal: {
    id: 'tidal',
    name: '潮鳍兽',
    stage: 'rookie',
    branch: 'ocean',
    silhouette: 'compact sea beast with one large fin and a bubble tail',
    palette: ['sea blue', 'foam white', 'coral mint'],
    features: ['bubble fins', 'tidal stripe', 'playful sea face'],
  },
  reef: {
    id: 'reef',
    name: '珊潮海兽',
    stage: 'champion',
    branch: 'ocean',
    silhouette: 'marine guardian with coral shoulders and wave tail',
    palette: ['reef teal', 'coral orange', 'seafoam'],
    features: ['coral crown', 'wave fins', 'ruin motifs'],
  },
  spark: {
    id: 'spark',
    name: '电啾兽',
    stage: 'baby',
    branch: 'thunder',
    silhouette: 'small speed cub with electric cheek spikes',
    palette: ['electric yellow', 'warm brown', 'sky blue'],
    features: ['spark cheeks', 'dash tail', 'fast grin'],
  },
  cipher: {
    id: 'cipher',
    name: '秘码团兽',
    stage: 'baby',
    branch: 'secret',
    silhouette: 'rounded archive spirit with floating glyph scraps',
    palette: ['paper white', 'cipher blue', 'ink navy'],
    features: ['rune tags', 'seal eye', 'quiet mystery'],
  },
  glitch: {
    id: 'glitch',
    name: '断章兽',
    stage: 'rookie',
    branch: 'secret',
    silhouette: 'fragmented pet with asymmetrical archive plates',
    palette: ['ice white', 'archive blue', 'glitch violet'],
    features: ['broken sigils', 'offset tail', 'sealed jaw line'],
  },
  sigil: {
    id: 'sigil',
    name: '印纹龙兽',
    stage: 'champion',
    branch: 'secret',
    silhouette: 'forbidden dragon with layered sigil armor',
    palette: ['holy white', 'runic blue', 'ink black'],
    features: ['seal horns', 'floating script', 'vault chest plate'],
  },
  paradox: {
    id: 'paradox',
    name: '零界圣兽',
    stage: 'ultimate',
    branch: 'secret',
    silhouette: 'sacred glitch beast with broken halo geometry',
    palette: ['void white', 'cipher cyan', 'abyss navy'],
    features: ['fractured halo', 'zero-point chest mark', 'sacred distortion'],
  },
};

function send(message) {
  const json = JSON.stringify(message);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(json, 'utf8')}\r\n\r\n${json}`);
}

function textResult(text) {
  return {
    content: [{ type: 'text', text }],
  };
}

function errorResult(id, message) {
  send({
    jsonrpc: '2.0',
    id,
    error: {
      code: -32000,
      message,
    },
  });
}

function buildPrompt(speciesId, opts = {}) {
  const species = SPECIES[speciesId];
  if (!species) {
    throw new Error(`Unknown species_id: ${speciesId}`);
  }

  const branch = BRANCHES[species.branch];
  const stageLabel = STAGE_LABELS[species.stage] ?? species.stage;
  const styleBias = opts.style_bias ?? 'premium cute retro pixel mascot';
  const outputMode = opts.output_mode ?? 'concept sheet';
  const extraNotes = opts.extra_notes ? `\nExtra notes:\n- ${opts.extra_notes}` : '';

  return `Use Seele AI to design a new pixel-pet style for my Flutter virtual pet game.

Target creature:
- species_id: ${species.id}
- Chinese name: ${species.name}
- branch: ${branch.label}
- stage: ${stageLabel}

Project direction:
- retro handheld virtual pet vibe
- 16x16 and 24x24 sprite readability first
- premium, memorable, mascot-friendly
- avoid copying Digimon, Pokemon, Tamagotchi, or any existing IP
- keep low-noise silhouettes and disciplined palettes

Branch identity:
- keywords: ${branch.keywords.join(', ')}
- contrast: ${branch.contrast}

Creature brief:
- silhouette: ${species.silhouette}
- palette suggestion: ${species.palette.join(', ')}
- notable features: ${species.features.join(', ')}
- style bias: ${styleBias}

What I need:
1. one strong final visual direction for this creature
2. a readable idle pose for tiny pixel scale
3. expression variations for idle, happy, battle, sleepy, sick, and sad
4. a palette with 4-6 main colors plus 1 optional accent
5. notes for how this design should evolve from or into nearby stages
6. implementation notes suitable for Flutter sprite production

Output mode:
- ${outputMode}
- include a concise Chinese-friendly naming refinement only if it improves brand feel
- keep the final answer structured and production-oriented${extraNotes}`;
}

function buildBatchPrompt(branchId, opts = {}) {
  const branch = BRANCHES[branchId];
  if (!branch) {
    throw new Error(`Unknown branch_id: ${branchId}`);
  }

  const speciesLines = branch.species
    .map((id) => SPECIES[id])
    .filter(Boolean)
    .map((item) => `- ${item.name} (${item.id}, ${STAGE_LABELS[item.stage] ?? item.stage})`)
    .join('\n');

  const focus = opts.focus ?? 'unified roster direction';

  return `Use Seele AI to expand the ${branch.label} branch for my Flutter digital pet game.

Branch goal:
- ${focus}
- retro handheld pixel-pet readability
- premium mascot appeal
- clear evolution continuity from early form to advanced form

Branch identity:
- ${branch.keywords.join(', ')}
- ${branch.contrast}

Species in scope:
${speciesLines}

What I need:
1. a unified art direction for the full branch
2. silhouette rules by stage
3. palette and shading rules
4. expression rules for idle, happy, battle, sleepy, sick, sad
5. one flagship design recommendation for the strongest branch face
6. concise implementation notes for Flutter sprite production

Important:
- keep results compatible with 16x16 and 24x24 sprites
- avoid noisy texture
- avoid direct imitation of existing monster IP`;
}

function loadQueue() {
  try {
    const text = fs.readFileSync(QUEUE_PATH, 'utf8');
    const rows = [];
    for (const line of text.split('\n')) {
      const match = line.match(/^\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*`([^`]+)`\s*\|\s*([^|]+)\s*\|$/);
      if (!match || match[1] === 'species_id') continue;
      rows.push({
        species_id: match[1].trim(),
        name: match[2].trim(),
        character_id: match[3].trim(),
        status: match[4].trim(),
      });
    }
    return rows;
  } catch {
    return [];
  }
}

function handleRequest(request) {
  const { id, method, params } = request;

  if (method === 'initialize') {
    send({
      jsonrpc: '2.0',
      id,
      result: {
        protocolVersion: '2024-11-05',
        capabilities: {
          tools: {},
        },
        serverInfo: {
          name: 'seeles-bridge',
          version: '0.1.0',
        },
      },
    });
    return;
  }

  if (method === 'notifications/initialized') {
    return;
  }

  if (method === 'tools/list') {
    send({
      jsonrpc: '2.0',
      id,
      result: {
        tools: [
          {
            name: 'compose_pet_style_brief',
            description: 'Generate a Seeles-ready prompt for one pet species in this Flutter pet project.',
            inputSchema: {
              type: 'object',
              properties: {
                species_id: {
                  type: 'string',
                  description: 'Project species id, such as bubble, sunbit, halo, ember, pearl.',
                },
                style_bias: {
                  type: 'string',
                  description: 'Optional extra style bias, such as premium cute retro pixel mascot.',
                },
                output_mode: {
                  type: 'string',
                  description: 'Optional output mode hint, such as concept sheet or sprite prompt.',
                },
                extra_notes: {
                  type: 'string',
                  description: 'Optional extra production note to include in the prompt.',
                },
              },
              required: ['species_id'],
            },
          },
          {
            name: 'compose_branch_style_brief',
            description: 'Generate a Seeles-ready art direction prompt for a full evolution branch.',
            inputSchema: {
              type: 'object',
              properties: {
                branch_id: {
                  type: 'string',
                  description: 'One of warm_light, flame, star_dream, forest, night_shadow, ocean, thunder, secret.',
                },
                focus: {
                  type: 'string',
                  description: 'Optional focus, such as unified roster direction or flagship mascot refinement.',
                },
              },
              required: ['branch_id'],
            },
          },
          {
            name: 'list_pet_queue',
            description: 'Read the existing character queue document and return species generation status.',
            inputSchema: {
              type: 'object',
              properties: {
                status: {
                  type: 'string',
                  description: 'Optional status filter, such as pending or completed.',
                },
              },
            },
          },
          {
            name: 'list_supported_species',
            description: 'List the project species and branch metadata that the Seeles bridge understands.',
            inputSchema: {
              type: 'object',
              properties: {},
            },
          },
        ],
      },
    });
    return;
  }

  if (method === 'tools/call') {
    const args = params?.arguments ?? {};
    try {
      if (params?.name === 'compose_pet_style_brief') {
        send({
          jsonrpc: '2.0',
          id,
          result: textResult(buildPrompt(args.species_id, args)),
        });
        return;
      }

      if (params?.name === 'compose_branch_style_brief') {
        send({
          jsonrpc: '2.0',
          id,
          result: textResult(buildBatchPrompt(args.branch_id, args)),
        });
        return;
      }

      if (params?.name === 'list_pet_queue') {
        const rows = loadQueue();
        const filtered = args.status
          ? rows.filter((row) => row.status.toLowerCase() === String(args.status).toLowerCase())
          : rows;
        send({
          jsonrpc: '2.0',
          id,
          result: textResult(JSON.stringify(filtered, null, 2)),
        });
        return;
      }

      if (params?.name === 'list_supported_species') {
        const payload = {
          branches: BRANCHES,
          species: Object.values(SPECIES).map((item) => ({
            id: item.id,
            name: item.name,
            stage: item.stage,
            branch: item.branch,
          })),
        };
        send({
          jsonrpc: '2.0',
          id,
          result: textResult(JSON.stringify(payload, null, 2)),
        });
        return;
      }

      errorResult(id, `Unknown tool: ${params?.name}`);
    } catch (error) {
      errorResult(id, error instanceof Error ? error.message : String(error));
    }
    return;
  }

  if (method === 'ping') {
    send({
      jsonrpc: '2.0',
      id,
      result: {},
    });
    return;
  }

  errorResult(id, `Unsupported method: ${method}`);
}

let buffer = Buffer.alloc(0);
let contentLength = null;

process.stdin.on('data', (chunk) => {
  buffer = Buffer.concat([buffer, chunk]);

  while (true) {
    if (contentLength === null) {
      const headerEnd = buffer.indexOf('\r\n\r\n');
      if (headerEnd === -1) {
        return;
      }

      const headerText = buffer.subarray(0, headerEnd).toString('utf8');
      const headers = headerText.split('\r\n');
      const contentLengthHeader = headers.find((line) => line.toLowerCase().startsWith('content-length:'));

      if (!contentLengthHeader) {
        throw new Error('Missing Content-Length header');
      }

      contentLength = Number.parseInt(contentLengthHeader.split(':')[1].trim(), 10);
      buffer = buffer.subarray(headerEnd + 4);
    }

    if (buffer.length < contentLength) {
      return;
    }

    const body = buffer.subarray(0, contentLength).toString('utf8');
    buffer = buffer.subarray(contentLength);
    contentLength = null;

    const request = JSON.parse(body);
    handleRequest(request);
  }
});
