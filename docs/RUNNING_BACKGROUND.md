# Backend'i Arka Planda / Otomatik Başlatma

Varsayılan olarak backend, `cargo run -p mental-ai-server` ile elle başlatılan bir süreçtir (bkz. `scripts/run_backend.ps1`). Sürekli bir araştırma servisi olması isteniyorsa (bilgisayara her girişte otomatik başlasın, terminal açık tutmaya gerek kalmasın) aşağıdaki kurulum kullanılır.

## Kurulum (bir kere, kendi terminalinde)

`MENTAL_AI_LLM_API_KEY` zaten kalıcı bir kullanıcı ortam değişkeni olarak ayarlanmış olmalı (bkz. ana README). Sonra:

```powershell
schtasks /Create /TN "MentalAI Backend" /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"G:\mental-ai\scripts\start-backend-background.ps1\"" /SC ONLOGON /RL LIMITED /F
powershell -NoProfile -File "G:\mental-ai\scripts\start-backend-background.ps1"
```

İlk satır görevi kaydeder (her oturum açılışında tetiklenir), ikinci satır beklemeden hemen şimdi başlatır. Yönetici hakkı gerektirmez, Windows şifreni saklamaz (`/RL LIMITED`, sadece oturum açıkken çalışır).

## Nasıl çalışıyor

- `scripts/start-backend-background.ps1`: `target/release/mental-ai-server.exe`'i görünmez bir pencerede başlatır. Zaten çalışıyorsa hiçbir şey yapmaz. API anahtarı yoksa `backend/data/startup.log`'a yazıp sessizce çıkar.
- `scripts/stop-backend-background.ps1`: arka plandaki süreci durdurur.

## Kod üzerinde değişiklik yapılacaksa

Çalışan `.exe` Windows'ta kilitli olduğu için yeniden derlemeden önce durdurulması gerekir:

```powershell
powershell -NoProfile -File "G:\mental-ai\scripts\stop-backend-background.ps1"
cd G:\mental-ai\backend
cargo build --release -p mental-ai-server
powershell -NoProfile -File "G:\mental-ai\scripts\start-backend-background.ps1"
```

## Kaldırmak istersen

```powershell
powershell -NoProfile -File "G:\mental-ai\scripts\stop-backend-background.ps1"
schtasks /Delete /TN "MentalAI Backend" /F
```
