/* SELECT
bar_kodu AS barkod,
sto_isim AS isim,
CAST(STOK_SATIS_FIYAT_LISTELERI.sfiyat_fiyati AS DECIMAL(8,2)) * (1-ISNULL(isk_isk1_yuzde,0)/100) AS fiyat,
dbo.fn_DovizSembolu(sfiyat_doviz) AS doviz
FROM
STOKLAR,
BARKOD_TANIMLARI,
STOK_SATIS_FIYAT_LISTELERI
LEFT OUTER JOIN
STOK_CARI_ISKONTO_TANIMLARI ON isk_stok_kod = sfiyat_iskontokod
WHERE
STOKLAR.sto_kod = BARKOD_TANIMLARI.bar_stokkodu
AND STOKLAR.sto_kod = STOK_SATIS_FIYAT_LISTELERI.sfiyat_stokkod
AND STOK_SATIS_FIYAT_LISTELERI.sfiyat_listesirano = 1
AND BARKOD_TANIMLARI.bar_kodu = '8683543743133'; */