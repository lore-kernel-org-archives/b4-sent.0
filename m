From: Ye He <ye.he@amlogic.com>
Date: Tue, 02 Dec 2025 16:40:11 +0800
Subject: [PATCH bluez v9 1/3] profiles: Add bearer field to btd_profile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251202-bearer-impl-v9-1-21602a82ad7c@amlogic.com>
References: <20251202-bearer-impl-v9-0-21602a82ad7c@amlogic.com>
In-Reply-To: <20251202-bearer-impl-v9-0-21602a82ad7c@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764664813; l=13682;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=iJknXYj5/qJnw3R4q7z1tmxHYi/nmqwl9k1IYJRo4HA=;
 b=3Br98Fx6WmW0NksBvcb7vYgsMbcNPzHOKfXlqBwD02GPnsxdzZs05OLeicTyVTSOsZ6cI7Eoa
 //0xUS5sRTCAAYc7CnRIXQhuXqMqptj81JZxH9IFGf22O4imT0pAmNS
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bearer filed into btd_profile to indicates which bearer
type this profile belongs to. Thus we can distinct the services
per bearer.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 profiles/audio/a2dp.c            |  5 +++--
 profiles/audio/asha.c            |  1 +
 profiles/audio/avrcp.c           |  2 ++
 profiles/audio/bap.c             |  2 ++
 profiles/audio/bass.c            |  1 +
 profiles/audio/ccp.c             |  1 +
 profiles/audio/csip.c            |  2 ++
 profiles/audio/mcp.c             |  1 +
 profiles/audio/micp.c            |  1 +
 profiles/audio/vcp.c             |  1 +
 profiles/battery/battery.c       |  1 +
 profiles/deviceinfo/deviceinfo.c |  1 +
 profiles/gap/gas.c               |  1 +
 profiles/health/hdp_manager.c    |  2 ++
 profiles/input/hog.c             |  1 +
 profiles/input/manager.c         |  1 +
 profiles/midi/midi.c             |  1 +
 profiles/network/manager.c       |  3 +++
 profiles/scanparam/scan.c        |  1 +
 src/profile.h                    | 10 ++++++++++
 20 files changed, 37 insertions(+), 2 deletions(-)

diff --git a/profiles/audio/a2dp.c b/profiles/audio/a2dp.c
index d8f24eaebc745a6d91a8207f6595f0b90d982c39..7a37003a2b25a9e931b8efdfc974368f5ab2bac8 100644
--- a/profiles/audio/a2dp.c
+++ b/profiles/audio/a2dp.c
@@ -3757,8 +3757,9 @@ static void media_server_remove(struct btd_adapter *adapter)
 static struct btd_profile a2dp_source_profile = {
 	.name		= "a2dp-source",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
-
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.remote_uuid	= A2DP_SOURCE_UUID,
+
 	.device_probe	= a2dp_source_probe,
 	.device_remove	= a2dp_source_remove,
 
@@ -3773,7 +3774,7 @@ static struct btd_profile a2dp_source_profile = {
 static struct btd_profile a2dp_sink_profile = {
 	.name		= "a2dp-sink",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
-
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.remote_uuid	= A2DP_SINK_UUID,
 	.device_probe	= a2dp_sink_probe,
 	.device_remove	= a2dp_sink_remove,
diff --git a/profiles/audio/asha.c b/profiles/audio/asha.c
index e870ea06f03ac1c20e5b29fb158c815aa2ce756c..8e625fdca32ff0b40efd43e394b34559627bde8c 100644
--- a/profiles/audio/asha.c
+++ b/profiles/audio/asha.c
@@ -499,6 +499,7 @@ static int asha_source_disconnect(struct btd_service *service)
 static struct btd_profile asha_source_profile = {
 	.name		= "asha-source",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= ASHA_PROFILE_UUID,
 	.experimental	= true,
 
diff --git a/profiles/audio/avrcp.c b/profiles/audio/avrcp.c
index 21bc80bbd095da49788a87357fd67c8e96ab779d..e6f7e1bfde9879ab6bf028e16384d474332fe805 100644
--- a/profiles/audio/avrcp.c
+++ b/profiles/audio/avrcp.c
@@ -4868,6 +4868,7 @@ done:
 
 static struct btd_profile avrcp_target_profile = {
 	.name		= "audio-avrcp-target",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 
 	.remote_uuid	= AVRCP_TARGET_UUID,
 	.device_probe	= avrcp_target_probe,
@@ -4951,6 +4952,7 @@ done:
 
 static struct btd_profile avrcp_controller_profile = {
 	.name		= "avrcp-controller",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 
 	.remote_uuid	= AVRCP_REMOTE_UUID,
 	.device_probe	= avrcp_controller_probe,
diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index 85bba9543974e5bf2a1ff6380c36e518ebc095ac..a03a120ddaaed7e261d40ac06a8f9502c52772bc 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -3865,6 +3865,7 @@ static void bap_adapter_remove(struct btd_profile *p,
 static struct btd_profile bap_profile = {
 	.name		= "bap",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= PACS_UUID_STR,
 	.device_probe	= bap_probe,
 	.device_remove	= bap_remove,
@@ -3879,6 +3880,7 @@ static struct btd_profile bap_profile = {
 static struct btd_profile bap_bcast_profile = {
 	.name		= "bcaa",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= BCAAS_UUID_STR,
 	.device_probe	= bap_bcast_probe,
 	.device_remove	= bap_bcast_remove,
diff --git a/profiles/audio/bass.c b/profiles/audio/bass.c
index 9ace372376f9452050724360c2c28e7cdcf1391b..8886a27d99b63b37e2937d8d70f71dfeda3d9ef2 100644
--- a/profiles/audio/bass.c
+++ b/profiles/audio/bass.c
@@ -2172,6 +2172,7 @@ static void bass_server_remove(struct btd_profile *p,
 static struct btd_profile bass_service = {
 	.name		= "bass",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= BASS_UUID_STR,
 	.device_probe	= bass_probe,
 	.device_remove	= bass_remove,
diff --git a/profiles/audio/ccp.c b/profiles/audio/ccp.c
index 8aa537b044e13b6d6a773645b420161bedca13ef..fb85045bb8ba1ec47a33856af1129d0ef78bf500 100644
--- a/profiles/audio/ccp.c
+++ b/profiles/audio/ccp.c
@@ -208,6 +208,7 @@ ccp_server_remove(struct btd_profile *p,
 static struct btd_profile ccp_profile = {
 	.name		= "ccp",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= GTBS_UUID_STR,
 	.device_probe	= ccp_probe,
 	.device_remove	= ccp_remove,
diff --git a/profiles/audio/csip.c b/profiles/audio/csip.c
index b8f29ddf852231d89760d6fe7ca2cfd684236570..d766c3da951899d990aa59132b820737604b1b7c 100644
--- a/profiles/audio/csip.c
+++ b/profiles/audio/csip.c
@@ -303,6 +303,7 @@ static void csip_remove(struct btd_service *service)
 static struct btd_profile csip_profile = {
 	.name		= "csip",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= CSIS_UUID_STR,
 
 	.device_probe	= csip_probe,
@@ -442,6 +443,7 @@ static void csis_server_remove(struct btd_profile *p,
 static struct btd_profile csis_profile = {
 	.name		= "csis",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.local_uuid	= CSIS_UUID_STR,
 
 	.adapter_probe	= csis_server_probe,
diff --git a/profiles/audio/mcp.c b/profiles/audio/mcp.c
index 6651b0897e6f631906b1467f5a479737541da286..8d4eed64399195533ac13fd075d7196a35cf2113 100644
--- a/profiles/audio/mcp.c
+++ b/profiles/audio/mcp.c
@@ -383,6 +383,7 @@ static void media_control_server_remove(struct btd_profile *p,
 static struct btd_profile mcp_profile = {
 	.name			= "mcp",
 	.priority		= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= GMCS_UUID_STR,
 	.device_probe	= mcp_probe,
 	.device_remove	= mcp_remove,
diff --git a/profiles/audio/micp.c b/profiles/audio/micp.c
index f1fb133897320677225a1c8bee06b4a1214f14fa..475f32daf75c06dc28ca72420a80e30802e5a3e9 100644
--- a/profiles/audio/micp.c
+++ b/profiles/audio/micp.c
@@ -300,6 +300,7 @@ static void micp_server_remove(struct btd_profile *p,
 static struct btd_profile micp_profile = {
 	.name		= "micp",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= MICS_UUID_STR,
 
 	.device_probe	= micp_probe,
diff --git a/profiles/audio/vcp.c b/profiles/audio/vcp.c
index 8949c71858e53448ee01c5c4261082f3912a759c..471ad59250386941c377e2f81e911467d7023cce 100644
--- a/profiles/audio/vcp.c
+++ b/profiles/audio/vcp.c
@@ -328,6 +328,7 @@ static void vcp_server_remove(struct btd_profile *p,
 static struct btd_profile vcp_profile = {
 	.name		= "vcp",
 	.priority	= BTD_PROFILE_PRIORITY_MEDIUM,
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= VCS_UUID_STR,
 
 	.device_probe	= vcp_probe,
diff --git a/profiles/battery/battery.c b/profiles/battery/battery.c
index 050234a0fa03813dc9e1b8302689fc68ec254184..2fe1f4aca2cf7b21e52bec989711741d6d7e25b5 100644
--- a/profiles/battery/battery.c
+++ b/profiles/battery/battery.c
@@ -327,6 +327,7 @@ static int batt_disconnect(struct btd_service *service)
 
 static struct btd_profile batt_profile = {
 	.name		= "batt-profile",
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= BATTERY_UUID,
 	.device_probe	= batt_probe,
 	.device_remove	= batt_remove,
diff --git a/profiles/deviceinfo/deviceinfo.c b/profiles/deviceinfo/deviceinfo.c
index f5adb101e312108be8dae20c75cc74e1ff7eaabf..e77bb50b457a28f08f3e9d2ecf8d81d80da86106 100644
--- a/profiles/deviceinfo/deviceinfo.c
+++ b/profiles/deviceinfo/deviceinfo.c
@@ -137,6 +137,7 @@ static int deviceinfo_disconnect(struct btd_service *service)
 
 static struct btd_profile deviceinfo_profile = {
 	.name		= "deviceinfo",
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= DEVICE_INFORMATION_UUID,
 	.device_probe	= deviceinfo_probe,
 	.device_remove	= deviceinfo_remove,
diff --git a/profiles/gap/gas.c b/profiles/gap/gas.c
index dd45554d43ebc267d40a8fe4a8fab48f602bf6bc..0f41c9e6c2a5c7d980509ae66d8d7d7c2678fd21 100644
--- a/profiles/gap/gas.c
+++ b/profiles/gap/gas.c
@@ -366,6 +366,7 @@ static int gap_disconnect(struct btd_service *service)
 
 static struct btd_profile gap_profile = {
 	.name		= "gap-profile",
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= GAP_UUID,
 	.device_probe	= gap_probe,
 	.device_remove	= gap_remove,
diff --git a/profiles/health/hdp_manager.c b/profiles/health/hdp_manager.c
index d1e627a3382a01bdd5002bcc0da01da35e872da1..72b69428036df77e2cdb224f186fb13191f955ed 100644
--- a/profiles/health/hdp_manager.c
+++ b/profiles/health/hdp_manager.c
@@ -57,6 +57,7 @@ static void hdp_driver_remove(struct btd_service *service)
 
 static struct btd_profile hdp_source_profile = {
 	.name		= "hdp-source",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.remote_uuid	= HDP_SOURCE_UUID,
 
 	.device_probe	= hdp_driver_probe,
@@ -68,6 +69,7 @@ static struct btd_profile hdp_source_profile = {
 
 static struct btd_profile hdp_sink_profile = {
 	.name		= "hdp-sink",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.remote_uuid	= HDP_SINK_UUID,
 
 	.device_probe	= hdp_driver_probe,
diff --git a/profiles/input/hog.c b/profiles/input/hog.c
index 1f5b82b774353244067e460f49aaccd09e26dcc8..f50a0f217f7f732f82645e289419e51ee6412917 100644
--- a/profiles/input/hog.c
+++ b/profiles/input/hog.c
@@ -215,6 +215,7 @@ static int hog_disconnect(struct btd_service *service)
 
 static struct btd_profile hog_profile = {
 	.name		= "input-hog",
+	.bearer		= BTD_PROFILE_BEARER_LE,
 	.remote_uuid	= HOG_UUID,
 	.device_probe	= hog_probe,
 	.device_remove	= hog_remove,
diff --git a/profiles/input/manager.c b/profiles/input/manager.c
index b0e415f6706c54e7c96199d3bb5e483d0927153f..0fcd6728c2fca83f03f7333f50102658553403e7 100644
--- a/profiles/input/manager.c
+++ b/profiles/input/manager.c
@@ -45,6 +45,7 @@ static void hid_server_remove(struct btd_profile *p,
 
 static struct btd_profile input_profile = {
 	.name		= "input-hid",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.local_uuid	= HID_UUID,
 	.remote_uuid	= HID_UUID,
 
diff --git a/profiles/midi/midi.c b/profiles/midi/midi.c
index 90e00a5f58361f1da57a71f393e581da5128310c..ea4719b95b23aa97850de362da9012728427f08e 100644
--- a/profiles/midi/midi.c
+++ b/profiles/midi/midi.c
@@ -458,6 +458,7 @@ static int midi_disconnect(struct btd_service *service)
 
 static struct btd_profile midi_profile = {
 	.name = "MIDI GATT Driver",
+	.bearer	= BTD_PROFILE_BEARER_LE,
 	.remote_uuid = MIDI_UUID,
 	.priority = BTD_PROFILE_PRIORITY_HIGH,
 	.auto_connect = true,
diff --git a/profiles/network/manager.c b/profiles/network/manager.c
index 51f382529df27600d1a4fd806cb656d7f1a682af..693547d45fbc5b2f227fed832b4efb8fb87c2d59 100644
--- a/profiles/network/manager.c
+++ b/profiles/network/manager.c
@@ -120,6 +120,7 @@ static void nap_server_remove(struct btd_profile *p,
 
 static struct btd_profile panu_profile = {
 	.name		= "network-panu",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.local_uuid	= NAP_UUID,
 	.remote_uuid	= PANU_UUID,
 	.device_probe	= connection_register,
@@ -132,6 +133,7 @@ static struct btd_profile panu_profile = {
 
 static struct btd_profile gn_profile = {
 	.name		= "network-gn",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.local_uuid	= PANU_UUID,
 	.remote_uuid	= GN_UUID,
 	.device_probe	= connection_register,
@@ -144,6 +146,7 @@ static struct btd_profile gn_profile = {
 
 static struct btd_profile nap_profile = {
 	.name		= "network-nap",
+	.bearer		= BTD_PROFILE_BEARER_BREDR,
 	.local_uuid	= PANU_UUID,
 	.remote_uuid	= NAP_UUID,
 	.device_probe	= connection_register,
diff --git a/profiles/scanparam/scan.c b/profiles/scanparam/scan.c
index 1c531773740c847e970ac45b7fbda2c0c9501ded..a66f80eabf3ef63e35cfd5e8da30e4aa18420b94 100644
--- a/profiles/scanparam/scan.c
+++ b/profiles/scanparam/scan.c
@@ -259,6 +259,7 @@ static int scan_param_probe(struct btd_service *service)
 
 static struct btd_profile scan_profile = {
 	.name = "Scan Parameters Client Driver",
+	.bearer	= BTD_PROFILE_BEARER_LE,
 	.remote_uuid = SCAN_PARAMETERS_UUID,
 	.device_probe = scan_param_probe,
 	.device_remove = scan_param_remove,
diff --git a/src/profile.h b/src/profile.h
index 424ce55ad65748ead13b1a38d67fbad6beb2b828..1281d8d9a0daa5de6578a5ae6df8fc211269d409 100644
--- a/src/profile.h
+++ b/src/profile.h
@@ -12,12 +12,22 @@
 #define BTD_PROFILE_PRIORITY_MEDIUM	1
 #define BTD_PROFILE_PRIORITY_HIGH	2
 
+#define BTD_PROFILE_BEARER_ANY		0
+#define BTD_PROFILE_BEARER_LE		1
+#define BTD_PROFILE_BEARER_BREDR	2
+
 struct btd_service;
 
 struct btd_profile {
 	const char *name;
 	int priority;
 
+	/* Indicates which bearer type this profile belongs to. Some profiles
+	 * may exist in both BR/EDR and LE, in which case they should be
+	 * registered with BTD_PROFILE_BEARER_ANY.
+	 */
+	int bearer;
+
 	const char *local_uuid;
 	const char *remote_uuid;
 

-- 
2.42.0

