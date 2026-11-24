# fix-biruni-wifi

Modern Linux dağıtımlarındaki (OpenSSL 3.x / TLS 1.3) sıkı güvenlik politikaları nedeniyle **Biruni_Student** (WPA2-Enterprise / PEAP-MSCHAPv2) kablosuz ağına bağlanamama sorununu çözen bash betiği.

## Kullanım

```bash
curl -fsSL https://raw.githubusercontent.com/06ergin06/fix-biruni-student-wifi/refs/heads/main/fix-biruni-student-wifi.sh | bash
```

## Ne Yapar?

1. `/etc/NetworkManager/system-connections/` dizininde kayıtlı `Biruni_Student` profilini kontrol eder:
   - **Profil varsa:** `[802-1x]` bloğunun altına `phase1-auth-flags=32` parametresini ekler.
   - **Profil yoksa:** Öğrenci numarası ve şifreyi alarak profili sıfırdan oluşturur.
2. NetworkManager yapılandırmasını yenileyip ağa bağlanır, ardından `biruni.edu.tr` ve `google.com` adreslerine ping atarak erişimi doğrular.
3. İlk deneme başarısız olursa ve sistemde `dnf` (Fedora/RHEL tabanlı dağıtımlar) bulunuyorsa `update-crypto-policies --set LEGACY` ayarını uygulayıp bağlantıyı tekrar test eder.


## Güvenlik ve Gizlilik

- Girilen öğrenci numarası ve şifre dışarıya aktarılmaz.
- Kimlik bilgileri yalnızca yerel sistemdeki `/etc/NetworkManager/system-connections/Biruni_Student.nmconnection` dosyasına `root:root` sahipliği ve `600` (sadece `root` okuyabilir) izniyle yazılır.

