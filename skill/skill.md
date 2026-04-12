---
name: team
description: "Agent takımlarını yönet: install (git repo'dan kur), list (kurulu takımları göster), remove (takım kaldır), update (takımı güncelle)."
argument-hint: "<install|list|remove|update> [repo-url veya team-name]"
---

# /team Skill — Agent Team Manager

Agent takımlarını git repo'lardan kurar, günceller ve kaldırır. Her takım agent'lar, skill'ler ve rule'lar içerebilir. Tümü global olarak `~/.claude/` altına symlink'lenir.

## Parametre Ayrıştırma

İlk kelime modu belirler: `install`, `list`, `remove`, `update`.

---

## `install` Modu

**Kullanım:** `/team install <git-repo-url>`

**Akış:**

1. Repo URL'ini al (HTTPS veya SSH)
2. Team adını repo adından çıkar (son segment, `.git` kaldırılır)
3. `~/agent-teams/{team-name}/` dizinine clone'la (zaten varsa `git pull`)
4. Repo içindeki yapıyı tara ve symlink'leri oluştur:

```bash
# Repo yapısı (convention):
{team-repo}/
├── agents/          → her .md dosyası ~/.claude/agents/'a symlink'lenir
├── skills/          → her alt dizin ~/.claude/skills/'a symlink'lenir
└── rules/           → her .md dosyası ~/.claude/rules/'a symlink'lenir
```

5. Symlink oluşturma kuralları:
   - `agents/*.md` → `~/.claude/agents/{dosya-adı}.md` (flat symlink)
   - `skills/{skill-name}/` → `~/.claude/skills/{skill-name}/` (dizin symlink)
   - `rules/*.md` → `~/.claude/rules/{dosya-adı}.md` (flat symlink)
   - İsim çakışması varsa **UYAR ve SORMA** — mevcut dosyanın üzerine yazma

6. `~/agent-teams/{team-name}/.team-manifest.json` oluştur:
```json
{
  "name": "software-project-team",
  "repo": "https://github.com/mkurak/agent-workshop-software-project-team.git",
  "installedAt": "2026-04-13T00:30:00Z",
  "symlinks": [
    { "source": "agents/api-agent.md", "target": "~/.claude/agents/api-agent.md" },
    { "source": "rules/brainstorm.md", "target": "~/.claude/rules/brainstorm.md" }
  ]
}
```

7. Kullanıcıya özet göster: kaç agent, skill, rule kuruldu.

**Komutlar (Bash ile çalıştırılacak):**

```bash
# Clone
TEAM_DIR="${HOME}/agent-teams/{team-name}"
git clone {repo-url} "${TEAM_DIR}" 2>/dev/null || (cd "${TEAM_DIR}" && git pull)

# Agents symlink
for f in "${TEAM_DIR}/agents/"*.md; do
  [ -f "$f" ] && ln -sf "$f" "${HOME}/.claude/agents/$(basename "$f")"
done

# Skills symlink (dizin bazlı)
for d in "${TEAM_DIR}/skills/"*/; do
  [ -d "$d" ] && ln -sf "$d" "${HOME}/.claude/skills/$(basename "$d")"
done

# Rules symlink
for f in "${TEAM_DIR}/rules/"*.md; do
  [ -f "$f" ] && ln -sf "$f" "${HOME}/.claude/rules/$(basename "$f")"
done
```

---

## `list` Modu

**Kullanım:** `/team list`

**Akış:**

1. `~/agent-teams/` dizinindeki her alt dizini tara
2. Her birinde `.team-manifest.json` varsa oku
3. Yoksa dizin yapısından say (agents/, skills/, rules/ altındaki dosyalar)
4. Tablo formatında göster:

```
Installed Teams:
─────────────────────────────────────────────────────
✅ software-project-team    6 agents  3 skills  2 rules
✅ youtube-team             3 agents  1 skill   0 rules
─────────────────────────────────────────────────────
Total: 2 teams, 9 agents, 4 skills, 2 rules
```

---

## `remove` Modu

**Kullanım:** `/team remove <team-name>`

**Akış:**

1. `~/agent-teams/{team-name}/` dizinini bul
2. `.team-manifest.json` varsa symlink listesini oradan oku
3. Yoksa `agents/`, `skills/`, `rules/` altındaki dosyaları tara
4. Her symlink'i `~/.claude/` altından kaldır (sadece symlink ise — gerçek dosyayı silme)
5. Kullanıcıya sor: "Kaynak dizini de sileyim mi? (~/agent-teams/{team-name}/)" — Evet/Hayır
6. Özet göster: kaç symlink kaldırıldı

**Komutlar:**

```bash
# Symlink'leri kaldır (sadece symlink olanları)
for f in "${HOME}/.claude/agents/"*.md; do
  [ -L "$f" ] && readlink "$f" | grep -q "agent-teams/{team-name}" && rm "$f"
done

for d in "${HOME}/.claude/skills/"*/; do
  [ -L "${d%/}" ] && readlink "${d%/}" | grep -q "agent-teams/{team-name}" && rm "${d%/}"
done

for f in "${HOME}/.claude/rules/"*.md; do
  [ -L "$f" ] && readlink "$f" | grep -q "agent-teams/{team-name}" && rm "$f"
done
```

---

## `update` Modu

**Kullanım:** `/team update <team-name>`

**Akış:**

1. `~/agent-teams/{team-name}/` dizinine git
2. `git pull` çalıştır
3. Yeni eklenen dosyalar için symlink oluştur (mevcut olanlar zaten güncel — symlink aynı dosyayı gösteriyor)
4. Silinen dosyalar için kırık symlink'leri temizle
5. Özet göster: güncellenen, eklenen, kaldırılan

**Komutlar:**

```bash
cd "${HOME}/agent-teams/{team-name}" && git pull

# Kırık symlink'leri temizle
find "${HOME}/.claude/agents" -type l ! -exec test -e {} \; -delete 2>/dev/null
find "${HOME}/.claude/skills" -type l ! -exec test -e {} \; -delete 2>/dev/null
find "${HOME}/.claude/rules" -type l ! -exec test -e {} \; -delete 2>/dev/null

# Yeni dosyalar için symlink ekle (mevcut olanlar atlanır)
for f in agents/*.md; do
  target="${HOME}/.claude/agents/$(basename "$f")"
  [ ! -e "$target" ] && ln -sf "$(pwd)/$f" "$target"
done
# ... skills ve rules için aynı
```

---

## Önemli Kurallar

1. **Symlink'ler her zaman `~/agent-teams/{name}/` → `~/.claude/` yönünde.** Tersi değil.
2. **İsim çakışması = uyarı.** Mevcut dosyanın üzerine yazılmaz. Kullanıcıya sorulur.
3. **Sadece symlink silinir.** `remove` komutu gerçek dosyayı asla silmez — sadece symlink kaldırılır.
4. **Manifest dosyası opsiyonel.** Yoksa dizin yapısından tüm bilgi çıkarılabilir. Ama varsa daha güvenilir.
5. **Convention-over-configuration.** Repo'da `agents/`, `skills/`, `rules/` dizin adları zorunlu. Başka isim tanınmaz.
