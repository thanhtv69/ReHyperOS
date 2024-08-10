# classes.dex

.class public Landroid/app/ApplicationStub;
.super Ljava/lang/Object;
.source "ApplicationStub.java"


# static fields
.field private static final mMiuiApplicationThread:Lmiui/process/IMiuiApplicationThread;


# direct methods
.method static constructor <clinit>()V
    .registers 1

    .line 13
    const/4 v0, 0x0

    sput-object v0, Landroid/app/ApplicationStub;->mMiuiApplicationThread:Lmiui/process/IMiuiApplicationThread;

    return-void
.end method

.method public constructor <init>()V
    .registers 1

    .line 11
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static onCreate(Landroid/app/Application;)V
    .registers 3

    invoke-static {}, Lmiui/contentcatcher/InterceptorProxy;->addMiuiApplication()V

    invoke-static {p0}, Lmiui/util/TypefaceUtils;->recordApplication(Landroid/app/Application;)V

    invoke-virtual {p0}, Landroid/app/Application;->getPackageName()Ljava/lang/String;

    move-result-object v0

    if-eqz p0, :cond_294
    
    const-string v1, "com.pubg.imobile"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_186
    
    const-string v1, "com.pubg.krmobile"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_186
    
    const-string v1, "com.rekoo.pubgm"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_186
    
    const-string v1, "com.tencent.ig"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_186
    
    const-string v1, "com.tencent.tmgp.pubgmhd"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_186
    
    const-string v1, "com.vng.pubgmobile"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_186
    
    goto :goto_44

    :cond_186
    const-string v1, "MODEL"

    const-string p0, "ASUS_AI2401_A"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string/jumbo p0, "asus"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_44

    const-string v1, "com.tencent.KiHan"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_2d

    const-string v1, "com.tencent.tmgp.cf"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_2d

    const-string v1, "com.tencent.tmgp.cod"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_2d

    const-string v1, "com.tencent.tmgp.gnyx"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_2d

    goto :goto_41

    :cond_2d
    const-string v1, "MODEL"

    const-string p0, "V2243A"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string/jumbo p0, "vivo"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_41
    const-string v1, "com.ea.gp.fifamobile"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_5a

    const-string v1, "com.pearlabyss.blackdesertm"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_5a

    const-string v1, "com.pearlabyss.blackdesertm.gl"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_5a

    goto :goto_6d

    :cond_5a
    const-string v1, "MODEL"

    const-string p0, "ASUS_I003D"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "asus"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_6d
    const-string v1, "com.epicgames.fortnite"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_8e

    const-string v1, "jp.konami.pesam"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_8e

    const-string v1, "com.tencent.lolm"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_8e

    const-string v1, "com.epicgames.portal"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_8e

    goto :goto_a8

    :cond_8e
    const-string v1, "MODEL"

    const-string p0, "LE2101"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "OnePlus"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "DEVICE"

    const-string p0, "OnePlus9Pro"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_a8
    const-string v1, "com.mobile.legends"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_c1

    const-string v1, "com.dts.freefireth"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_c1

    const-string v1, "com.dts.freefiremax"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_c1

    goto :goto_d4

    :cond_c1
    const-string v1, "MODEL"

    const-string p0, "ASUS_Z01QD"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "asus"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_d4
    const-string v1, "com.YoStar.AetherGazer"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_f5

    const-string v1, "MODEL"

    const-string/jumbo p0, "nubia"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "NX729J"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MODEL"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :cond_f5
    const-string v1, "com.tencent.tmgp.sgame"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_106

    const-string v1, "com.levelinfinite.sgameGlobal"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_106

    goto :goto_119

    :cond_106
    const-string v1, "MODEL"

    const-string p0, "2210132C"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "Xiaomi"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_119
    const-string v1, "com.proximabeta.mf.uamo"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_134

    const-string v1, "MODEL"

    const-string p0, "SHARK PRS-A0"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "blackshark"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :cond_134

    const-string v1, "com.riotgames.league.wildrift"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_185

    const-string v1, "com.riotgames.league.wildrifttw"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_185

    const-string v1, "com.riotgames.league.wildriftvn"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_185

    const-string v1, "com.netease.lztgglobal"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_185

    goto :goto_19f

    :cond_185
    const-string v1, "MODEL"

    const-string p0, "IN2020"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "OnePlus"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "DEVICE"

    const-string p0, "OnePlus8Pro"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_19f
    const-string v1, "com.riotgames.league.teamfighttacticsvn"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1d0

    const-string v1, "com.riotgames.league.teamfighttacticstw"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1d0

    const-string v1, "com.riotgames.league.teamfighttactics"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1d0

    const-string v1, "com.gameloft.android.ANMP.GloftA9HM"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1d0

    const-string v1, "com.madfingergames.legends"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1d0

    const-string v1, "com.activision.callofduty.shooter"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1d0

    goto :goto_1e3

    :cond_1d0
    const-string v1, "MODEL"

    const-string p0, "ASUS_AI2201"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "asus"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_1e3
    const-string v1, "com.tencent.tmgp.kr.codm"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1fc

    const-string v1, "com.vng.codmvn"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1fc

    const-string v1, "com.garena.game.codm"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1fc

    goto :goto_20f

    :cond_1fc
    const-string v1, "MODEL"

    const-string p0, "SO-52A"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "Sony"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_20f
    const-string v1, "com.levelinfinite.hotta.gp"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_230

    const-string v1, "com.ea.gp.apexlegendsmobilefps"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_230

    const-string v1, "com.vng.mlbbvn"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_230

    const-string v1, "com.supercell.clashofclans"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_230

    goto :goto_243

    :cond_230
    const-string v1, "MODEL"

    const-string p0, "21081111RG"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "Xiaomi"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "BRAND"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :goto_243
    const-string v1, "com.google.android.gms"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_277

    const-string v1, "BRAND"

    const-string p0, "google"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "PRODUCT"

    const-string p0, "sailfish"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "DEVICE"

    const-string p0, "sailfish"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "Google"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MODEL"

    const-string p0, "Pixel"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "ID"

    const-string p0, "OPM1.171019.011"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V
    
    const-string v1, "FINGERPRINT"

    const-string p0, "google/sailfish/sailfish:8.1.0/OPM1.171019.011/4448085:user/release-keys"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    invoke-static {}, Landroid/app/ApplicationStub;->setVersionFieldInt()V
    
    :cond_277
    const-string v1, "com.google.android.apps.photos"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_294

    const-string v1, "BRAND"

    const-string p0, "google"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MANUFACTURER"

    const-string p0, "Google"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    const-string v1, "MODEL"

    const-string p0, "Pixel XL"

    invoke-static {v1, p0}, Landroid/app/ApplicationStub;->setBuildField(Ljava/lang/String;Ljava/lang/String;)V

    :cond_294
    return-void
.end method

.method private static setBuildField(Ljava/lang/String;Ljava/lang/String;)V
    .registers 4

    :try_start_0
    const-class v0, Landroid/os/Build;

    invoke-virtual {v0, p0}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v0

    const/4 v1, 0x1

    invoke-virtual {v0, v1}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    const/4 v1, 0x0

    invoke-virtual {v0, v1, p1}, Ljava/lang/reflect/Field;->set(Ljava/lang/Object;Ljava/lang/Object;)V

    invoke-virtual {v0, v1}, Ljava/lang/reflect/Field;->setAccessible(Z)V
    :try_end_11
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_11} :catch_12

    goto :goto_16

    :catch_12
    move-exception v0

    invoke-virtual {v0}, Ljava/lang/Exception;->printStackTrace()V

    :goto_16
    return-void
.end method

.method private static setVersionFieldInt()V
    .registers 3

    .line 161
    :try_start_0
    const-class v0, Landroid/os/Build$VERSION;

    const-string v1, "DEVICE_INITIAL_SDK_INT"

    invoke-virtual {v0, v1}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v0

    .line 162
    .local v0, "field":Ljava/lang/reflect/Field;
    const/4 v1, 0x1

    invoke-virtual {v0, v1}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    .line 163
    const/4 v1, 0x0

    const/16 v2, 0x1a

    invoke-virtual {v0, v1, v2}, Ljava/lang/reflect/Field;->setInt(Ljava/lang/Object;I)V
    :try_end_12
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_12} :catch_13

    goto :goto_17

    :catch_13
    move-exception v0

    invoke-virtual {v0}, Ljava/lang/Exception;->printStackTrace()V

    :goto_17
    return-void
.end method
