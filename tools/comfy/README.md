# Локальный арт-пайплайн (ComfyUI)

Локальная, бесплатная генерация ассетов для игры: картинки (текст → изображение) и 3D-модели
(изображение → GLB). Всё считается на этой машине через ComfyUI по MCP-серверу `comfy`
(инструменты `tools.comfy.*`); partner-модели, облако и кредиты не используются.

- ComfyUI: `http://127.0.0.1:8188` (Comfy Desktop).
- Каталоги моделей, которые реально читает ComfyUI:
  - `D:\Programs\ComfyUI\Comfy Desktop\models` — основные;
  - `D:\Comfy-Desktop\ComfyUI-Shared\models` — общий (shared).
- `input` = `D:\Comfy-Desktop\ComfyUI-Shared\input`, `output` = `D:\Comfy-Desktop\ComfyUI-Shared\output`.

Workflow в репозитории — только для чтения. Копию для запуска делай в
`C:\Users\bikee\AppData\Local\Temp\opencode\`, слоты правь на копии.

## Файлы

| Файл | Что это |
| --- | --- |
| `workflows/flux3_klein_t2i.json` | FLUX.3 Klein int8, текст → картинка (31 нода, 30 конвертируемых) |
| `workflows/3d_pixal3d_trellis2_image_to_model.json` | Pixal3D / TRELLIS.2, картинка → 3D (GLB) (66 нод, 63 конвертируемых) |

Оба файла в формате UI Save Format (как сохраняет редактор ComfyUI), `validate_workflow` на них даёт
`valid: true`, `error_count: 0`.

## Workflow 1: текст → картинка (`flux3_klein_t2i.json`)

| Слот | Тип | Сейчас | Что задаёт |
| --- | --- | --- | --- |
| `28.value` | STRING | промпт-пример | основной промпт |
| `19.aspect_ratio` | COMBO | `16:9 (Widescreen)` | пропорции: `1:1 (Square)`, `2:3 (Portrait Photo)`, `3:2 (Photo)`, `3:4 (Portrait Standard)`, `4:3 (Standard)`, `9:16 (Portrait Widescreen)`, `16:9 (Widescreen)`, `21:9 (Ultrawide)` |
| `19.megapixels` | FLOAT | `4` | разрешение в мегапикселях |
| `152.seed` | INT | `19712744757275` | сид |
| `152.steps` | INT | `20` | шаги |
| `152.cfg` | FLOAT | `8` | CFG |
| `134.filename_prefix` | STRING | `flux3_klein_int8_t2i` | префикс имени файла в `output` |
| `137.unet_name` | COMBO | `flux3-image-klein-int8-convrot.safetensors` | основная модель (`diffusion_models`) |
| `138.clip_name` | COMBO | `qwen3vl_4b_int8_convrot.safetensors` | токенизатор/текст-энкодер |
| `139.vae_name` | COMBO | `flux2-vae.safetensors` | VAE |

Промпт-апсемплер (нода `156`, `CLIPLoader` с `qwen3.5_9b_flux3_prompt_upsampler_int8_convrot.safetensors`)
не трогай — это отдельная модель, а не основной текст-энкодер.

### Баг ноды 138 (уже исправлен здесь)

В сохранённом в ComfyUI файле нода `138` (`CLIPLoader`, заголовок «Text encoder») указывала
`clip_name = qwen3.5_9b_flux3_prompt_upsampler_int8_convrot.safetensors` — то есть модель апсемплера подключалась
как основной текст-энкодер, и генерация падала. Правильное значение —
`qwen3vl_4b_int8_convrot.safetensors`. В этой копии исправлено **только** оно (и в `widgets_values`,
и в `widgets_values_named`); если будешь брать workflow заново из ComfyUI — проверь ноду `138` первым делом.

## Workflow 2: картинка → 3D (`3d_pixal3d_trellis2_image_to_model.json`)

| Слот | Тип | Сейчас | Что задаёт |
| --- | --- | --- | --- |
| `122.image` | COMBO | `viking_wolf_rune_axe.png` | входная картинка из `input` ComfyUI (загружать `upload_file`) |
| `316.value` | BOOL | `false` | **движок**: `false` = Pixal3D, `true` = TRELLIS.2 |
| `314.switch`, `315.switch`, `318.switch` | BOOL | `false` | не влияют: входы `switch` связаны линками с выходом `316` |
| `248.switch` | BOOL | `true` | удаление фона (BiRefNet) |
| `288.value` | INT | `4096` | **мастер-ручка размера текстур**: UV-развёртка + запекание base color / ORM |
| `224.resolution` | INT | `2048` | размер normal map (`BakeNormalMapFromMesh`), независимый виджет |
| `233.resolution` | INT | `1024` | размер ambient occlusion (`BakeAmbientOcclusion`), независимый виджет |
| `186.target_face_count` | INT | `700000` | децимация меша, для игры — **10000–40000** |
| `186.placement_mode` | COMBO | `midpoint` | режим децимации (`midpoint` / `qem`) |
| `147.texture_size` | INT | `2048` | не влияет: вход `texture_size` связан линком с `288` |
| `196.resolution` | INT | `2048` | не влияет: вход `resolution` связан линком с `288` |
| `261.resolution` | INT | `1024` | только превью UV-атласа (`RenderUVAtlas`), на GLB не влияет |
| `322.width`, `322.height` | INT | `1024` | размер превью-рендера внутри `Save3DAdvanced`, на текстуры модели не влияет |
| `12.seed` | INT | `43` | сид |
| `12.steps` | INT | `12` | шаги |
| `12.cfg` | FLOAT | `1` | CFG |
| `322.filename_prefix` | STRING | `3d/ComfyUI` | префикс GLB в `output` |

### Переключатель движка (значим только `316.value`)

`false` = **Pixal3D**, `true` = **TRELLIS.2**. Задаётся **одним** слотом `316.value` (нода `PrimitiveBoolean`,
подписана «Switch to Trellis2»); подтверждение — заметка ноды `317`: «Set to `false` to use Pixal3D,
Set to `true` to use Trellis.2».

У узлов-переключателей `314`, `315`, `318` (`ComfySwitchNode`) есть свои виджеты `switch` (`314.switch`,
`315.switch`, `318.switch`), но их входы `switch` **связаны линками** с выходом `316` (`links` 1283 → `316:0`,
1284 → `316:0`, 1285 → `316:0`). Вход перекрывает виджет, поэтому эти три значения ни на что не влияют:
менять их бессмысленно, движок задаётся единственным слотом `316.value`.

### Размер модели: вес дают текстуры, а не полигоны

Замеры (GLB распакован, прочитаны встроенные PNG):

| прогон | движок | `186.target_face_count` | `288.value` | `224.resolution` | `233.resolution` | трисы / вершины | текстуры (PNG) | GLB |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Pixal3D | 40000 | 4096 | 2048 | 1024 | 40000 / 28304 | 4096², 4096², 2048² (6.78 + 6.79 + 2.56 МБ) | **17.89 МБ** |
| 2 | TRELLIS.2 | 12000 | 4096 | 2048 | 1024 | 11998 / 9707 | 4096², 4096², 2048² (6.13 + 7.46 + 2.60 МБ) | **16.77 МБ** |
| 3 | TRELLIS.2 | 12000 | **512** | **512** | **512** | 11996 / 9554 | 512² ×3 (0.23 + 0.23 + 0.29 МБ) | **1.33 МБ** |

Почти весь вес — встроенные PNG-карты (base color / normal / metallic-roughness-occlusion); сам меш на 12k трис
≈ 0.58 МБ. Уменьшение `target_face_count` в 3.3 раза (40000 → 12000) размер почти не меняет, а текстуры
4096 → 512 уменьшают файл в **12.6 раза**.

### Размер текстур: значим `288.value`, а `147` и `196` — обманки

Нода `288` (`PrimitiveInt`, title «Texture Resolution», дефолт `4096`) — мастер-ручка. Её выход разведён линками:
`1185` → `196.resolution` (`UnwrapMesh`, UV-развёртка) и `1186` → `147.texture_size` (`BakeTextureFromVoxel`,
запекание карт). Вход перекрывает виджет, поэтому `147.texture_size` (2048) и `196.resolution` (2048) **ни на что
не влияют** — проверено: прогон с `147.texture_size = 512` дал ровно те же 4096×4096 и те же 16.77 МБ.

Значимые слоты размера:

- `288.value` — UV-развёртка и запекание base color / metallic / roughness (мастер-ручка);
- `224.resolution` — normal map (`BakeNormalMapFromMesh`, дефолт `2048`), независимый виджет, линком не перекрыт;
- `233.resolution` — ambient occlusion (`BakeAmbientOcclusion`, дефолт `1024`), независимый виджет;
- `261.resolution` — только превью UV-атласа (`RenderUVAtlas`), на выходной GLB не влияет;
- `322.width` / `322.height` — размер превью-рендера в `Save3DAdvanced`, на текстуры модели не влияет.

Дефолты для игровых ассетов: `288.value = 512` (для крупных «геройских» объектов допустимо `1024`),
`224.resolution = 512`, `233.resolution = 512`, `186.target_face_count = 10000–40000`.
Ориентир по файлу — **0.5–2 МБ на модель**; больше 5 МБ для игрового ассета — повод уменьшить `288.value`.

### Децимация

`186.target_face_count` по умолчанию `700000` — «сырой» меш, для игры непригоден: ставь `10000`–`40000`
(порядка 10–40 тысяч треугольников). На размер GLB это влияет слабо (см. таблицу выше), но напрямую бьёт по
производительности Godot.

## Требуемые файлы моделей

Ставятся в `D:\Programs\ComfyUI\Comfy Desktop\models` (все уже на месте):

| Путь | Workflow |
| --- | --- |
| `diffusion_models/flux3-image-klein-int8-convrot.safetensors` | t2i, нода `137` |
| `text_encoders/qwen3vl_4b_int8_convrot.safetensors` | t2i, нода `138` |
| `text_encoders/qwen3.5_9b_flux3_prompt_upsampler_int8_convrot.safetensors` | t2i, нода `156` |
| `vae/flux2-vae.safetensors` | t2i, нода `139` |
| `clip_vision/dino_v3_L_naf_fp32.safetensors` | 3D |
| `diffusion_models/pixal3d_int8_convrot.safetensors` | 3D (Pixal3D) |
| `diffusion_models/trellis_2_int8_convrot.safetensors` | 3D (TRELLIS.2) |
| `vae/trellis_2_shape_vae_bf16.safetensors` | 3D |
| `vae/trellis_2_texture_vae_bf16.safetensors` | 3D |
| `geometry_estimation/moge_2_vitl_normal_fp16.safetensors` | 3D |
| `background_removal/birefnet.safetensors` | 3D (нода `248`) |

## Куда пишутся результаты

ComfyUI отдаёт файлы в `D:\Comfy-Desktop\ComfyUI-Shared\output` (`134.filename_prefix` / `322.filename_prefix`),
а `fetch_outputs(prompt_id=..., out_dir=...)` скачивает их в репозиторий:

- картинки → `E:\Games\TestGame\assets\generated\img\`;
- модели → `E:\Games\TestGame\assets\generated\models\<slug>\` — отдельная подпапка на ассет, потому что
  `fetch_outputs` тащит **все** выходы прогона (см. ниже).

### `fetch_outputs` не умеет фильтровать выходы

Параметры только `prompt_id`, `out_dir`, `url_only`, `inline_images` — фильтра по типу или ноде нет. Один 3D-прогон
вернул **11 файлов**: 8 временных превью PNG (`ComfyUI_temp_*.png` — PBR-карты и служебные), 2 промежуточных
`preview3d_advanced_*.glb` (0.22 и 0.34 МБ, `type=temp`) и один настоящий результат — `type=output` от ноды `322`
(`Save3DAdvanced`), в том прогоне `businessman_lowtex_00001.glb` на 1.33 МБ.

Как найти настоящий: `job(action="wait", prompt_id=...)` возвращает `outputs_by_node` — `outputs_by_node["322"]`
это URL нужного файла; всё с `type=temp` — мусор. На диске файлы называются
`<первые 8 символов prompt_id>_<NNN>.<ext>` (например `115fa9f9_010.glb`), порядок сохраняется как в списке выходов,
поэтому настоящий GLB — обычно последний `.glb`.

Кто чистит: у агента `artist` нет shell, он не удаляет и не переименовывает файлы. Он делает
`fetch_outputs(out_dir="…/assets/generated/models/<slug>/")` и в отчёте указывает, какой файл является результатом
ноды `322`; лишние файлы (temp-превью, промежуточные GLB) удаляет, а результат переименовывает в `<slug>.glb`
оркестратор или пользователь.

### Имена файлов

Это конвенция, а не гарантия. ComfyUI сам добавляет к `filename_prefix` счётчик (`<prefix>_00001_.png`),
а `fetch_outputs` сохраняет файл как `<первые 8 символов prompt_id>_<номер>.<ext>` — например
`7607d3b2_000.png`.

- `134.filename_prefix` задавай как `<slug>_<seed>` (картинка), `322.filename_prefix` — `<slug>` (модель):
  так результат удобно искать в `output` ComfyUI;
- в `assets/generated/` файл остаётся с тем именем, которое вернул `fetch_outputs`, — это нормально;
- `<slug>` — латиница в нижнем регистре через `_`;
- в отчёте указывай соответствие «slug → фактическое имя файла» (при желании файл в репозитории можно
  переименовать руками).

## VRAM

3D-прогон тяжёлый: после t2i из 17.1 ГБ на карте свободно ~2.4 ГБ, и с таким запасом 3D падает по OOM
(в логах это «потеря соединения», а не ошибка ноды). Перед 3D вызывай
`free_memory(unload_models=true, free_memory=true)` — освобождает до ~11–14.5 ГБ; `system_stats` показывает
`vram_free` до и после. Запущенный job `free_memory` не прерывает (для отмены — `job(action="cancel")`).

## Рецепт: текст → картинка → 3D

1. Скопируй workflow в `%TEMP%\opencode\` и задай слоты. Без shell это делается одной командой:
   `vary_workflow(workflow_path=..., slots=[{address: "28.value", values: ["..." ]}, {address: "152.seed", values: [123]}], out_dir="C:/Users/bikee/AppData/Local/Temp/opencode/run1")`
   (одно значение в списке = одна копия). Либо `set_workflow_slot(workflow_path=<копия>, overrides=[...], stdout=False)`.
2. `validate_workflow(workflow_path=<копия>)` → должно быть `valid: true`.
3. `run_workflow(workflow_path=<копия>, wait=false)` → вернёт `prompt_id`.
4. `job(action="wait", prompt_id=...)`, затем `fetch_outputs(prompt_id=..., out_dir="E:/Games/TestGame/assets/generated/img")`.
5. Для 3D: сначала `free_memory(unload_models=true, free_memory=true)` и проверь `vram_free` в `system_stats`;
   затем `upload_file(paths=[<путь к картинке>])` → имя файла в слот `122.image`, движок в `316.value`,
   `288.value` = `512` (крупный объект — `1024`), `224.resolution` = `512`, `233.resolution` = `512`,
   `186.target_face_count` = `10000..40000`, `12.seed`, `322.filename_prefix`.
6. `validate_workflow` → `run_workflow(wait=false)` → `job(action="wait")` →
   `fetch_outputs(prompt_id=..., out_dir="E:/Games/TestGame/assets/generated/models/<slug>")`; результат — тот файл,
   на который указывает `outputs_by_node["322"]` (`type=output`), остальное — мусор.

`confirm_spend` не передавай никогда: графы локальные, `spends_credits: false`.

## Типовые ошибки

| Симптом | Причина / что делать |
| --- | --- |
| `validate_workflow`: unknown node class `ComfySwitchNode` / `DecimateMesh` / `Save3DAdvanced` | не установлен пак нод для 3D: `workflow_deps` → `install_node(names=[...])` → `restart_comfyui`. `install_node` ставит сторонний код и требует подтверждения пользователя; если `workflow_deps` в этой сборке вернул ошибку — сообщить и остановиться, сам агент ничего не устанавливает |
| 3D-узел просит модель | нет файла из таблицы выше; `download_model` не использовать без разрешения пользователя — сообщить и остановиться |
| Генерация t2i падает на текст-энкодере | нода `138` смотрит на модель апсемплера → `qwen3vl_4b_int8_convrot.safetensors` |
| Модель весит 15–20 МБ | почти весь вес — текстуры: проверь `288.value` (дефолт `4096` → `512`), затем `224.resolution` и `233.resolution` (→ `512`); `147.texture_size`/`196.resolution` не помогут, они перекрыты линком |
| Модель тормозит в Godot / сотни тысяч трисов | забыт `186.target_face_count` (`700000` по умолчанию) → `10000–40000` |
| 3D-результат «не тот движок» | проверь `316.value` (`false` = Pixal3D, `true` = TRELLIS.2); `314.switch`/`315.switch`/`318.switch` перекрыты линком от `316` и не влияют |
| `connection refused` при `run_workflow` | ComfyUI не запущен (`server_info`) |
| OOM / потеря соединения посреди прогона | не хватило VRAM: перед 3D — `free_memory(unload_models=true, free_memory=true)`, плюс снизить `288.value` и `186.target_face_count` |
