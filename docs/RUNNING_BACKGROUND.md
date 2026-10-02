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

## Bekçi (watchdog)

Oturum açılışındaki görevler süreçleri yalnızca bir kez başlatır. Backend ya da ngrok sonradan çökerse (güncelleme, hata, kopan tünel) bir sonraki oturum açılışına kadar kapalı kalırdı. `scripts/watchdog.ps1` her 5 dakikada bir önce yerel `/health`'i, sonra ngrok üzerinden genel adresi dener ve yalnızca düşen parçayı yeniden başlatır. Her yeniden başlatma `backend/data/watchdog.log`'a bir satır yazar; her şey yolundaysa hiçbir şey yazmaz.

Kurulum (bir kere, yönetici hakkı gerekmez; `conhost --headless` pencere açılmasını engeller):

```powershell
schtasks /Create /TN "MentalAI Watchdog" /TR "conhost.exe --headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File G:\mental-ai\scripts\watchdog.ps1" /SC MINUTE /MO 5 /RL LIMITED /F
```

Sınırı: görevler oturum açıkken çalışır. Bilgisayar yeniden başlar ve kimse oturum açmazsa (ör. gece Windows Update yeniden başlatması) sunucu, oturum açılana kadar kapalı kalır.

## Kod üzerinde değişiklik yapılacaksa

Çalışan `.exe` Windows'ta kilitli olduğu için yeniden derlemeden önce durdurulması gerekir:

```powershell
powershell -NoProfile -File "G:\mental-ai\scripts\stop-backend-background.ps1"
cd G:\mental-ai\backend
cargo build --release -p mental-ai-server
powershell -NoProfile -File "G:\mental-ai\scripts\start-backend-background.ps1"
```

Sunucuyu derleme süresince (birkaç dakika) kapatmamak için ayrı bir klasörde derleyip yalnızca exe'yi değiştir — kesinti birkaç saniye sürer:

```powershell
cd G:\mental-ai\backend
cargo build --release -p mental-ai-server --target-dir target-staging
powershell -NoProfile -File "G:\mental-ai\scripts\stop-backend-background.ps1"
Copy-Item target-staging\release\mental-ai-server.exe target\release\mental-ai-server.exe -Force
powershell -NoProfile -File "G:\mental-ai\scripts\start-backend-background.ps1"
```

## Kaldırmak istersen

```powershell
powershell -NoProfile -File "G:\mental-ai\scripts\stop-backend-background.ps1"
schtasks /Delete /TN "MentalAI Backend" /F
```

## ngrok tüneli (TestFlight / telefon erişimi için)

Uygulama backend'e `https://status-enticing-easeful.ngrok-free.dev` (ngrok'un ücretsiz statik domain'i) üzerinden bağlanır. Bilgisayar yeniden başlayınca tünelin de kendiliğinden kalkması için backend'dekine benzer ikinci bir görev vardır:

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "G:\mental-ai\scripts\start-ngrok-background.ps1"'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "MentalAI ngrok" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
```

- `scripts/start-ngrok-background.ps1`: ngrok'u gizli pencerede başlatır, zaten çalışıyorsa hiçbir şey yapmaz. Çıktısı `backend/data/ngrok.log`'a gider; ngrok bulunamazsa `backend/data/startup.log`'a yazar.
- Tünel açık mı kontrol: `https://status-enticing-easeful.ngrok-free.dev/health` 200 dönmeli.
- Elle durdurmak: `Stop-Process -Name ngrok`. Kaldırmak: `Unregister-ScheduledTask -TaskName "MentalAI ngrok" -Confirm:$false`.
