# ILERLEME

Ajan panosu çalışmasının adım adım kayıt defteri. Her adımın sonunda buraya bir kayıt eklenir; yeni bir oturum önce son kaydı okuyarak başlar. Kurallar: [AGENTS.md](AGENTS.md).

## Kayıt şablonu

```
## Adım N — Başlık
- Tarih/saat: (date komutuyla)
- Ne yapıldı:
- Eklenen/değişen dosyalar:
- Testler: X test, Y doğrulama, 0 hata
- Commit mesajı:
- Açık kalanlar / notlar:
- Ceyda'nın süresi: (boş bırak)
```

## Adım 0 — Hazırlık
- Tarih/saat: 2026-10-24 16:27:39 +03:00
- Ne yapıldı: Çalışma düzeni kuruldu, özellik kodu yazılmadı. `AGENT.md` → `AGENTS.md` olarak yeniden adlandırıldı (`git mv`); kökte tek satırlık `CLAUDE.md` (`@AGENTS.md`) oluşturuldu; AGENTS.md'ye "Ajan panosu çalışma kuralları" bölümü eklendi; `ILERLEME.md` ve `CHALLENGE_LOG.md` oluşturuldu. README ve PROJE_DURUMU'ndaki `AGENT.md` bağlantıları `AGENTS.md`'ye güncellendi.
- Eklenen/değişen dosyalar: AGENTS.md (eski AGENT.md), CLAUDE.md, ILERLEME.md, CHALLENGE_LOG.md, README.md, PROJE_DURUMU.md
- Testler: 34 test, 114 doğrulama, 0 hata (RuboCop ve Brakeman temiz)
- Commit mesajı: Adım 0: Hazırlık — AGENTS.md, CLAUDE.md, ILERLEME.md ve CHALLENGE_LOG.md ile çalışma düzeni kuruldu
- Açık kalanlar / notlar: `PROJE_DURUMU.md` ve `odev.md` önceden takip edilmiyordu (untracked); bu commit'e yalnızca çalışma düzeni dosyaları alındı, ikisi dışarıda bırakıldı.
- Ceyda'nın süresi:
