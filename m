From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Wed, 17 Jun 2026 12:26:14 +0300
Subject: [PATCH v5 2/5] ufs: Expose selected UFS functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-ufs_tool2-v5-2-1cf099f71111@mobileye.com>
References: <20260617-ufs_tool2-v5-0-1cf099f71111@mobileye.com>
In-Reply-To: <20260617-ufs_tool2-v5-0-1cf099f71111@mobileye.com>
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Tawfik Bayouk <tawfik.bayouk@mobileye.com>, 
 Vladimir Kondratiev <vladimir.Kondratiev@mobileye.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=21355;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=unPHi062ct0o/NxqzX2skor9nBwxti4HHHVomPADUNA=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqMmhDLZgbE5zPnXxt6vFCVF+zLC+HHurNCVL5s
 tNfIA+8r6+JAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCajJoQwAKCRCfmumUluiO
 Oe1DEACyeRyFrqpsFFcUH0eLcXeLguKyRAVonIqs+t/11J5/THNr/abqWAzlKIzKnml0Dv42iPT
 bgbuczl5eRVb441gy4xowBe86RHvASBAshrQP8UskKlce+OFnxQhPQqISEnhsaest6Bp4L3SD/N
 t2Ti4bKY8bnbSlcLGehxQemOtZFQM9t03T5Ap0gYo4JWkWheksKPmpqyA3AdHWIiE5NC8M+mLBv
 85jjD2HflMiCSQxj9OhwFBMvbO9mLnOPKOBeI6k01PBGE6pn80j4jthPslxvIIbMv37XwX0cotp
 piAfi/m8/jfWu+xY3M3mUSBo7m2Qfk1buQvmYAuN/fk+Ip+/b4W3jdHi9ee39MH13Y2xGeaZDTd
 QgAz87ez6edSAoNiB9DDyGsbiCPnP6UpMqR+bz6JKzBYxepdC2fKcLN9PD9H/DVrtWXTteNL8Vh
 cyeRsbVTdX4QTCzmEHnZe+G7JjXKw7YsXPO18rsXNqn9LwnUqo5kwMc2u2CLp4eeAfj8a3wEn26
 A+sEmUE8Q89GHoKZDCCnYi0o90v125wSILbA94n/rfXvOiFuJFXlIS2/0R904S0O9pLU3/gRoBn
 J9T0axW/8sSfA8Pq89mczqXiQK12JrweZmRPvViVHqtBcgqxa1qx7cUDLxcNz0CG7q0Um+SnSZQ
 neK7XfztBMEBYPg==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

    Remove the static qualifier from selected functions to allow
    future reuse. Add flags according to UFS 3.1.

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 drivers/ufs/ufs-uclass.c |  18 +-
 drivers/ufs/ufs.h        |  52 ------
 include/ufs.h            | 421 +++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 430 insertions(+), 61 deletions(-)

diff --git a/drivers/ufs/ufs-uclass.c b/drivers/ufs/ufs-uclass.c
index 6a51f337e47..78f6064ddea 100644
--- a/drivers/ufs/ufs-uclass.c
+++ b/drivers/ufs/ufs-uclass.c
@@ -757,7 +757,7 @@ static inline u8 ufshcd_get_upmcrs(struct ufs_hba *hba)
  *
  * Flush cache in aligned address..address+size range.
  */
-static void ufshcd_cache_flush(void *addr, unsigned long size)
+void ufshcd_cache_flush(void *addr, unsigned long size)
 {
 	uintptr_t start_addr = (uintptr_t)addr & ~(ARCH_DMA_MINALIGN - 1);
 	uintptr_t end_addr = ALIGN((uintptr_t)addr + size, ARCH_DMA_MINALIGN);
@@ -1089,8 +1089,8 @@ static inline void ufshcd_init_query(struct ufs_hba *hba,
 /**
  * ufshcd_query_flag() - API function for sending flag query requests
  */
-static int ufshcd_query_flag(struct ufs_hba *hba, enum query_opcode opcode,
-			     enum flag_idn idn, bool *flag_res)
+int ufshcd_query_flag(struct ufs_hba *hba, enum query_opcode opcode,
+		      enum flag_idn idn, bool *flag_res)
 {
 	struct ufs_query_req *request = NULL;
 	struct ufs_query_res *response = NULL;
@@ -1320,9 +1320,9 @@ out:
 /**
  * ufshcd_query_descriptor_retry - API function for sending descriptor requests
  */
-static int ufshcd_query_descriptor_retry(struct ufs_hba *hba, enum query_opcode opcode,
-					 enum desc_idn idn, u8 index, u8 selector,
-					 u8 *desc_buf, int *buf_len)
+int  ufshcd_query_descriptor_retry(struct ufs_hba *hba, enum query_opcode opcode,
+				   enum desc_idn idn, u8 index, u8 selector,
+				   u8 *desc_buf, int *buf_len)
 {
 	int err;
 	int retries;
@@ -1457,9 +1457,9 @@ static int ufshcd_map_desc_id_to_length(struct ufs_hba *hba, enum desc_idn desc_
  * ufshcd_read_desc_param - read the specified descriptor parameter
  *
  */
-static int ufshcd_read_desc_param(struct ufs_hba *hba, enum desc_idn desc_id,
-				  int desc_index, u8 param_offset,
-				  u8 *param_read_buf, u8 param_size)
+int ufshcd_read_desc_param(struct ufs_hba *hba, enum desc_idn desc_id,
+			   int desc_index, u8 param_offset,
+			   u8 *param_read_buf, u8 param_size)
 {
 	int ret;
 	u8 *desc_buf;
diff --git a/drivers/ufs/ufs.h b/drivers/ufs/ufs.h
index 0f6c93fbce7..03c0a46a4cf 100644
--- a/drivers/ufs/ufs.h
+++ b/drivers/ufs/ufs.h
@@ -43,15 +43,6 @@ struct ufs_pwr_mode_info {
 	struct ufs_pa_layer_attr info;
 };
 
-enum ufs_desc_def_size {
-	QUERY_DESC_DEVICE_DEF_SIZE		= 0x40,
-	QUERY_DESC_CONFIGURATION_DEF_SIZE	= 0x90,
-	QUERY_DESC_UNIT_DEF_SIZE		= 0x23,
-	QUERY_DESC_INTERCONNECT_DEF_SIZE	= 0x06,
-	QUERY_DESC_GEOMETRY_DEF_SIZE		= 0x48,
-	QUERY_DESC_POWER_DEF_SIZE		= 0x62,
-	QUERY_DESC_HEALTH_DEF_SIZE		= 0x25,
-};
 
 struct ufs_desc_size {
 	int dev_desc;
@@ -162,19 +153,6 @@ enum {
 	MASK_TM_FUNC			= 0xFF,
 };
 
-/* UTP QUERY Transaction Specific Fields OpCode */
-enum query_opcode {
-	UPIU_QUERY_OPCODE_NOP		= 0x0,
-	UPIU_QUERY_OPCODE_READ_DESC	= 0x1,
-	UPIU_QUERY_OPCODE_WRITE_DESC	= 0x2,
-	UPIU_QUERY_OPCODE_READ_ATTR	= 0x3,
-	UPIU_QUERY_OPCODE_WRITE_ATTR	= 0x4,
-	UPIU_QUERY_OPCODE_READ_FLAG	= 0x5,
-	UPIU_QUERY_OPCODE_SET_FLAG	= 0x6,
-	UPIU_QUERY_OPCODE_CLEAR_FLAG	= 0x7,
-	UPIU_QUERY_OPCODE_TOGGLE_FLAG	= 0x8,
-};
-
 /* bRefClkFreq attribute values */
 enum ufs_ref_clk_freq {
 	REF_CLK_FREQ_19_2_MHZ	= 0,
@@ -205,21 +183,6 @@ enum {
 	UPIU_COMMAND_SET_TYPE_QUERY	= 0x2,
 };
 
-/* Flag idn for Query Requests*/
-enum flag_idn {
-	QUERY_FLAG_IDN_FDEVICEINIT			= 0x01,
-	QUERY_FLAG_IDN_PERMANENT_WPE			= 0x02,
-	QUERY_FLAG_IDN_PWR_ON_WPE			= 0x03,
-	QUERY_FLAG_IDN_BKOPS_EN				= 0x04,
-	QUERY_FLAG_IDN_LIFE_SPAN_MODE_ENABLE		= 0x05,
-	QUERY_FLAG_IDN_PURGE_ENABLE			= 0x06,
-	QUERY_FLAG_IDN_RESERVED2			= 0x07,
-	QUERY_FLAG_IDN_FPHYRESOURCEREMOVAL		= 0x08,
-	QUERY_FLAG_IDN_BUSY_RTC				= 0x09,
-	QUERY_FLAG_IDN_RESERVED3			= 0x0A,
-	QUERY_FLAG_IDN_PERMANENTLY_DISABLE_FW_UPDATE	= 0x0B,
-};
-
 /* Attribute idn for Query requests */
 enum attr_idn {
 	QUERY_ATTR_IDN_BOOT_LU_EN		= 0x00,
@@ -247,21 +210,6 @@ enum attr_idn {
 	QUERY_ATTR_IDN_PSA_DATA_SIZE		= 0x16,
 };
 
-/* Descriptor idn for Query requests */
-enum desc_idn {
-	QUERY_DESC_IDN_DEVICE		= 0x0,
-	QUERY_DESC_IDN_CONFIGURATION	= 0x1,
-	QUERY_DESC_IDN_UNIT		= 0x2,
-	QUERY_DESC_IDN_RFU_0		= 0x3,
-	QUERY_DESC_IDN_INTERCONNECT	= 0x4,
-	QUERY_DESC_IDN_STRING		= 0x5,
-	QUERY_DESC_IDN_RFU_1		= 0x6,
-	QUERY_DESC_IDN_GEOMETRY		= 0x7,
-	QUERY_DESC_IDN_POWER		= 0x8,
-	QUERY_DESC_IDN_HEALTH           = 0x9,
-	QUERY_DESC_IDN_MAX,
-};
-
 enum desc_header_offset {
 	QUERY_DESC_LENGTH_OFFSET	= 0x00,
 	QUERY_DESC_DESC_TYPE_OFFSET	= 0x01,
diff --git a/include/ufs.h b/include/ufs.h
index f6e27d90e43..da51988d93e 100644
--- a/include/ufs.h
+++ b/include/ufs.h
@@ -2,6 +2,64 @@
 #ifndef _UFS_H
 #define _UFS_H
 
+#include <linux/types.h>
+
+/* Descriptor idn for Query requests */
+enum desc_idn {
+	QUERY_DESC_IDN_DEVICE		= 0x0,
+	QUERY_DESC_IDN_CONFIGURATION	= 0x1,
+	QUERY_DESC_IDN_UNIT		= 0x2,
+	QUERY_DESC_IDN_RFU_0		= 0x3,
+	QUERY_DESC_IDN_INTERCONNECT	= 0x4,
+	QUERY_DESC_IDN_STRING		= 0x5,
+	QUERY_DESC_IDN_RFU_1		= 0x6,
+	QUERY_DESC_IDN_GEOMETRY		= 0x7,
+	QUERY_DESC_IDN_POWER		= 0x8,
+	QUERY_DESC_IDN_HEALTH           = 0x9,
+	QUERY_DESC_IDN_MAX,
+};
+
+/* Flag idn for Query Requests*/
+enum flag_idn {
+	QUERY_FLAG_IDN_FDEVICEINIT			= 0x01,
+	QUERY_FLAG_IDN_PERMANENT_WPE			= 0x02,
+	QUERY_FLAG_IDN_PWR_ON_WPE			= 0x03,
+	QUERY_FLAG_IDN_BKOPS_EN				= 0x04,
+	QUERY_FLAG_IDN_LIFE_SPAN_MODE_ENABLE		= 0x05,
+	QUERY_FLAG_IDN_PURGE_ENABLE			= 0x06,
+	QUERY_FLAG_IDN_RESERVED2			= 0x07,
+	QUERY_FLAG_IDN_FPHYRESOURCEREMOVAL		= 0x08,
+	QUERY_FLAG_IDN_BUSY_RTC				= 0x09,
+	QUERY_FLAG_IDN_RESERVED3			= 0x0A,
+	QUERY_FLAG_IDN_PERMANENTLY_DISABLE_FW_UPDATE	= 0x0B,
+	QUERY_FLAG_IDN_F_WRITE_BOOSTER_EN               = 0x0E,
+	QUERY_FLAG_IDN_F_WB_BUF_FLUSH_EN                = 0x0F,
+	QUERY_FLAG_IDN_F_WB_BUF_FLUSH_HIBERN8           = 0x10
+};
+
+enum ufs_desc_def_size {
+	QUERY_DESC_DEVICE_DEF_SIZE		= 0x40,
+	QUERY_DESC_CONFIGURATION_DEF_SIZE	= 0x90,
+	QUERY_DESC_UNIT_DEF_SIZE		= 0x23,
+	QUERY_DESC_INTERCONNECT_DEF_SIZE	= 0x06,
+	QUERY_DESC_GEOMETRY_DEF_SIZE		= 0x48,
+	QUERY_DESC_POWER_DEF_SIZE		= 0x62,
+	QUERY_DESC_HEALTH_DEF_SIZE		= 0x25,
+};
+
+/* UTP QUERY Transaction Specific Fields OpCode */
+enum query_opcode {
+	UPIU_QUERY_OPCODE_NOP		= 0x0,
+	UPIU_QUERY_OPCODE_READ_DESC	= 0x1,
+	UPIU_QUERY_OPCODE_WRITE_DESC	= 0x2,
+	UPIU_QUERY_OPCODE_READ_ATTR	= 0x3,
+	UPIU_QUERY_OPCODE_WRITE_ATTR	= 0x4,
+	UPIU_QUERY_OPCODE_READ_FLAG	= 0x5,
+	UPIU_QUERY_OPCODE_SET_FLAG	= 0x6,
+	UPIU_QUERY_OPCODE_CLEAR_FLAG	= 0x7,
+	UPIU_QUERY_OPCODE_TOGGLE_FLAG	= 0x8,
+};
+
 struct udevice;
 
 /**
@@ -20,4 +78,367 @@ int ufs_probe(void);
  */
 int ufs_probe_dev(int index);
 
+/*
+ * In a QUERY REQUEST UPIU, the Device Descriptor
+ * is addressed setting: DESCRIPTOR IDN = 00h
+ */
+struct ufs_device_desc {
+	u8 length;		/* Size of this descriptor */
+	u8 descriptor_idn;	/* Descriptor Type Identifier (00h) */
+	u8 device;		/* Device type (00h: Device) */
+	u8 device_class;
+	/* UFS Device Class (00h: Mass Storage) */
+	u8 device_sub_class;
+	/* UFS Mass Storage Subclass (e.g., 00h: Embedded Bootable) */
+	u8 protocol;
+	/* Protocol supported by UFS Device (00h: SCSI) */
+	u8 number_lu;
+	/* Number of Logical units (non-well known)  */
+	u8 number_wlu;
+	/* Number of Well known Logical units (MDV = 04h) */
+	u8 boot_enable;	/* Boot Enable (01h: enabled) */
+	u8 descr_access_en;
+	/* Descriptor Access Enable during partial boot initialization */
+
+	/* --- power Management & Priority (Offset 0x0A) --- */
+	u8 init_power_mode;
+	/* Initial power Mode after device initi (00h: UFS-Sleep, 01h: */
+	/*   Active) [4, 5] */
+	u8 high_priority_lun;
+	/* High Priority Logical unit (7Fh if all LUs have same priority) */
+	u8 secure_removal_type;
+	/* Secure Removal Type (00h: erase, 01h: overwrite/erase, etc.) */
+	u8 security_lu;
+	/* Support for security LU (01h: RPMB) */
+	u8 background_ops_term_lat;
+	/* Background Operations Termination Latency (in units of 10 ms) */
+	u8 init_active_icc_level;
+	/* Initial Active ICC Level after power on/reset (00h to 0Fh) */
+
+	/* --- Version, Naming, & configuration Pointers (Offset 0x10) --- */
+	u16 spec_version;
+	/* Specification version in BCD format (e.g., 3.1 = 0310h) */
+	u16 manufacture_date;	/* Manufacturing Date in BCD format */
+	u8 manufacturer_name;
+	/* Index to the Manufacturer Name string descriptor */
+	u8 product_name;
+	/* Index to the Product Name string descriptor */
+	u8 serial_number;
+	/* Index to the Serial Number string descriptor */
+	u8 oem_id;
+	/* Index to the OEM ID string descriptor */
+	u16 manufacturer_id;
+	/* Manufacturer ID code and Bank Index (JEP106 definition) */
+	u8 ud0_base_offset;
+	/* Offset of unit Descriptor 0 configurable parameters within the */
+	/* configuration Descriptor */
+	u8 config_length;
+	/* Total size of the configurable unit Descriptor parameters */
+	u8 device_rtt_cap;
+	/* Maximum number of outstanding Ready To Transfer (RTT) UPIUs */
+	/* supported  (min 2) */
+	u16 periodic_rtc_update;
+	/* Frequency and method of Real-Time Clock update */
+
+	/* --- Feature Support & Device Status (Offset 0x1F) --- */
+	u8 ufs_features_support;
+	/* Bitmap indicating supported UFS features (FFU, PSA, etc.) */
+	u8 ffu_timeout;
+	/* Field Firmware Update Timeout (in seconds) */
+	u8 queue_depth;
+	/* Queue Depth (0: per-LU queueing; 1-255: shared queue depth) */
+	u16 device_version;	/* Device Version */
+	u8 num_secure_wp_area;
+	/* Total number of Secure Write Protect */
+	/* Areas supported (max 32) */
+	u32 psa_max_data_size;
+	/* PSA Maximum Data Size (in units of 4 Kbyte) */
+	u8 psa_state_timeout;
+	/* PSA State Timeout (max command timeout for b_psa_state change) */
+	u8 product_revision_level;
+	/* Index to the Product Revision Level string descriptor */
+	u8 reserved_2bh[18];	/* reserved */
+	u8 reserved_30h[19];
+	/* Reserved for Unified Memory Extension standard */
+	u8 reserved_40h[20];
+	/* Reserved for Host Performance Booster (HPB) Extension Standard */
+	u8 reserved_43h[21];	/* Reserved */
+
+	/* --- Extended Feature Support (Offset 0x4F) --- */
+	u32 extended_ufs_features_support;
+	/* Extended UFS Features Support (including WriteBooster, */
+	/* offset 53h Performance Throttling) */
+	u8 write_booster_buffer_preserve_user_space_en;
+	/* offset 54h Preserve User Space mode for WriteBooster Buffer */
+	u8 write_booster_buffer_type;
+	/*  offset 55h WriteBooster Buffer Type
+	 *  (0h:dedicated buffer,01h: shared buffer)
+	 */
+	u32 num_shared_write_booster_buffer_allocunits;
+	/* WriteBooster Buffer size for shared configuration */
+	/* (in Allocation units) */
+} __packed;
+
+struct ufs_unit_desc {
+	u8 length;		/* Size of this descriptor (Default: 2Dh) */
+	u8 descriptor_idn;	/* unit Descriptor Type Identifier (02h) */
+	u8 bunit_index;		/* The index of the Logical unit */
+
+	/* --- configuration Parameters --- */
+	u8 lu_enable;		/* 01h: LU enabled, 00h: LU disabled */
+	u8 boot_lun_id;
+	/* 01h: Boot LU A, 02h: Boot LU B, 00h: Not bootable */
+	u8 lu_write_protect;
+	/* 01h: power-on WP, 02h: Permanent WP, 00h: None */
+	u8 lu_queue_depth;
+	/* LU-specific queue depth (0 if shared queuing is used) */
+	u8 psa_sensitive;
+	/* 01h: Sensitive to soldering, 00h: Not sensitive */
+	u8 memory_type;
+	/* Memory type (e.g., 00h: Normal, 01h: System Code) */
+	u8 data_reliability;
+	/* 01h: Data protected against power failure */
+	u8 logical_block_size;
+	/* Logical Block Size exponent (e.g., 0Ch = 4 Kbyte) */
+
+	/* --- Capacity and geometry --- */
+	u64 logical_block_count;
+	/* Total number of addressable logical blocks in the LU */
+	u32 erase_block_size;
+	/* Optimal granularity for erase/discard operations */
+	u8 provisioning_type;
+	/* 00h: Full, 02h: Thin (TPRZ=0), 03h: Thin (TPRZ=1) */
+	u64 phy_mem_resource_count;
+	/* Total physical memory resources available to the LU */
+
+	/* --- Performance and Extended Features --- */
+	u16 context_capabilities;
+	/* Bits [3:0]: MaxContextID; Bits [6:4]: Large unit Multiplier */
+	u8 largeunit_granularity_M1;
+	/* Large unit Granularity = 1MB * (value + 1) */
+	u8 reserved[11];	/* Reserved for HPB Extension Standard */
+	u32 lu_num_write_booster_buffer_allocunits;
+	/* WriteBooster Buffer size in Allocation units */
+} __packed;
+
+/*
+ *
+ * UFS Geometry Descriptor (IDN 07h)
+ * Total Size: 87 bytes (0x57)
+ */
+struct ufs_geometry_desc {
+	/* --- Descriptor Header (Offset 0x00) --- */
+	u8 length;		/* Size of this descriptor (57h) */
+	u8 descriptor_idn;	/* geometry Descriptor ID (07h) */
+	u8 media_technology;	/* Reserved (00h) */
+	u8 reserved_03h;	/* Reserved (00h) */
+
+	/* --- Capacity and Device geometry (Offset 0x04) --- */
+	u64 total_raw_device_capacity; /* Total memory available (units of 512B) */
+	u8 max_number_lu;	/* Max LUs: 00h (8 LUs) or 01h (32 LUs) */
+	u32 segment_size;	/* Segment size (units of 512B) */
+	u8 allocationunit_size;	/* Allocation unit Size (number of segments) */
+	u8 min_addr_block_size;
+	/* Min addressable block size (units of 512B, min 08h) */
+	u8 optimal_read_block_size;	/* Optimal read granularity (units of 512B) */
+	u8 optimal_write_block_size;	/* Optimal write granularity (units of 512B) */
+	u8 max_in_buffer_size;	/* Max data-in buffer size (units of 512B) */
+	u8 max_out_buffer_size;	/* Max data-out buffer size (units of 512B) */
+	u8 rpmb_read_write_size;	/* Max RPMB frames (256B) per command */
+	u8 dynamic_capacity_resource_policy;	/* 00h: per LU, 01h: per memory type */
+	u8 data_ordering;	/* 01h: Out-of-order data transfer supported */
+	u8 max_contex_id_number;	/* Maximum supported contexts (min 5) */
+	u8 sys_data_tagunit_size;	/* Granularity for System Data Tagging */
+	u8 sys_data_tag_res_size;	/* Max storage area for system data tagging */
+	u8 supported_sec_r_types;	/* Bitmap of supported Secure Removal Types */
+	u16 supported_memory_types;
+	/* Bitmap of supported memory types (Normal, Enhanced, etc.) */
+
+	/* --- Memory Type Capacity and Factors (Offset 0x20) --- */
+	u32 system_code_max_n_alloc_u;
+	/* Max Allocation units for System Code memory */
+	u16 system_code_cap_adj_fac;
+	/* Capacity Adjustment Factor for System Code */
+	u32 non_persist_max_n_alloc_u;
+	/* Max Allocation units for Non-Persistent memory */
+	u16 non_persist_cap_adj_fac;
+	/* Capacity Adjustment Factor for Non-Persistent */
+	u32 enhanced1_max_n_alloc_u;
+	/* Max Allocation units for Enhanced memory */
+	/* Capacity Adjustment Factor for Enhanced */
+	u16 enhanced1_cap_adj_fac;
+	u32 enhanced2_max_n_alloc_u;
+	/* Max Allocation units for Enhanced memory */
+	/* Capacity Adjustment Factor for Enhanced */
+	u16 enhanced2_cap_adj_fac;
+	u32 enhanced3_max_n_alloc_u;
+	/* Max Allocation units for Enhanced memory */
+	/* Capacity Adjustment Factor for Enhanced */
+	u16 enhanced3_cap_adj_fac;
+	u32 enhanced4_max_n_alloc_u;
+	/* Max Allocation units for Enhanced memory */
+	/* Capacity Adjustment Factor for Enhanced */
+	u16 enhanced4_cap_adj_fac;
+	/* --- Performance Optimization (Offset 0x44) --- */
+	/* Optimal Logical Block Size per memory type */
+	u32 optimal_logical_block_size;
+	u8  reserved_hpb[4]; // 48h: Reserved for HPB Extension
+	u16 reserved2;   // 4Dh: Reserved
+	/* WriteBooster Parameters */
+	/* 4Fh: Max total WriteBooster Buffer size */
+	u32 write_booster_buffer_max_alloc_units;
+	/* 53h: Max LUs supporting WriteBooster (Valid: 1) */
+	u8  device_max_write_booster_lus;
+	/* 54h: LBA space reduction factor (e.g., 3 for TLC) */
+	u8  write_booster_buffer_capadjfac;
+	/* 55h: User space vs Preserve types */
+	u8  supported_write_booster_buffer_userspace_reduction_types;
+	/* 56h: LU based vs Shared buffer type */
+	u8  supported_write_booster_buffer_types;
+} __packed;
+
+/**
+ * UFS configuration Descriptor - Header and Device configurable Parameters
+ * Based on Table 14.10 (INDEX = 00h)
+ */
+struct config_descriptor {
+	/* --- Descriptor Header --- */
+	u8 length;
+	/* 00h: Size of this descriptor (MDV: E6h) */
+	u8 descriptor_idn;
+	/* 01h: configuration Descriptor Type ID (01h) */
+
+	/* --- configuration Flow Control --- */
+	u8 conf_desc_continue;
+	/* 02h: 00h = Last descriptor (apply config); */
+	/* 01h = More descriptors follow */
+
+	/* --- Device Descriptor configurable Parameters --- */
+	u8 boot_enable;
+	/* 03h: Enables boot feature (01h: enabled) */
+	u8 descr_access_en;
+	/* 04h: Enables Device Descriptor access after partial init */
+	u8 initpower_mode;
+	/* 05h: Initial power Mode after reset (01h: Active) */
+	u8 high_priority_lun;
+	/* 06h: LUN of the high priority logical unit */
+	u8 secure_removal_type;
+	/* 07h: configures secure removal (e.g., 00h: erase) */
+	u8 init_active_icc_level;
+	/* 08h: Initial ICC level after reset (00h-0Fh) */
+	u16 periodic_rtc_update;
+	/* 09h: Frequency/method of Real-Time Clock update */
+	u8 reserved_HPB;
+	/* 0Bh: Reserved for Host Performance Booster */
+
+	/* --- RPMB configuration Parameters --- */
+	u8 rpmb_region_enable;
+	/* 0Ch: Bitmask to enable RPMB regions 1-3 */
+	u8 rpmb_region1_size;
+	/* 0Dh: Size of RPMB region 1 in 128KB units */
+	u8 rpmb_region2_size;
+	/* 0Eh: Size of RPMB region 2 in 128KB units */
+	u8 rpmb_region3_size;
+	/* 0Fh: Size of RPMB region 3 in 128KB units */
+
+	/* --- WriteBooster configuration Parameters --- */
+	u8 write_booster_buffer_preserve_user_space_en;
+	/* 10h: 01h = Preserve user space */
+	u8 write_booster_buffer_type;
+	/* 11h: 00h = Dedicated LU; 01h = Shared */
+	u32 num_shared_write_booster_buffer_allocunits;
+	/* 12h: Shared buffer size in Alloc units */
+} __packed;
+
+/**
+ * UFS unit Descriptor configurable Parameters
+ * Found within the configuration Descriptor (IDN: 01h)
+ * Based on Table 14.12
+ */
+struct ufs_unit_cfg_parameters {
+	u8 lu_enable;		/* 01h: Enabled, 00h: Disabled */
+
+	u8 boot_lun_id;		/* 0 Not Bootable,1-A or 2-B */
+
+	/* 01h: Boot LU A, 02h: Boot LU B, 00h: Not bootable */
+	u8 lu_write_protect;
+	/* 00h: None, 01h: power-on WP, 02h: Permanent WP */
+	u8 memory_type;
+	/* Memory type (00h: Normal, 01h: System Code) */
+
+	/* Number of allocation units assigned to the LU. */
+	u32 num_allocunits;
+
+	u8 data_reliability; /* 01h: Protected against power failure */
+
+	/* Block size exponent (e.g., 0Ch = 4 KB) */
+	u8 logical_block_size;
+
+	/* 00h: Full, 02h: Thin (TPRZ=0), 03h: Thin (TPRZ=1) */
+	u8 provisioning_type;
+
+	u16 context_capabilities; /* LU Context support and multipliers */
+
+	u8 reserved_0dh[6];	/* Reserved */
+
+	u8 reserved_hpb[7];
+	/* Reserved for Host Performance Booster Extension */
+
+	u32 lu_num_write_booster_buffer_allocunits;
+	/* WriteBooster Buffer size in Allocation units. */
+} __packed;
+
+#define UFS_DESC_SIZE (unsigned char)0xff
+
+struct ufs_config_desc {
+	struct config_descriptor cfg_desc;
+	/*
+	 * NOTE: For INDEX = 00h, configurable parameters
+	 * for unit Descriptors 0 to 7
+	 */
+	/* follow this header at the offset defined
+	 * by b_ud0_base_offset
+	 */
+	unsigned char space[UFS_DESC_SIZE];
+} __packed;
+
+/**
+ * UFS power Parameter Element Format
+ * Based on Table 7.13
+ */
+struct ufs_power_parameter_element {
+	/* Bits [15:14]: unit (00b:n_a, 01b:u_a, 10b:m_a, 11b:A) */
+	/* Bits [13:10]: Reserved (0000b) */
+	/* Bits [9:0]:   Value (Maximum current expected) */
+	u16 upower_value;
+};
+
+/**
+ * UFS power Parameters Descriptor (IDN: 08h)
+ * Based on Table 14.16
+ */
+struct ufs_power_param_desc {
+	/* Offset 00h */
+	u8 length;		/* Size of descriptor (62h) */
+	u8 descriptor_idn;	/* Descriptor Type ID (08h) */
+
+	/* Offset 02h: Maximum current for VCC (16 levels) */
+	struct ufs_power_parameter_element active_icc_levels_vcc[5];
+	/* Offset 22h: Maximum current for VCCQ (16 levels) */
+	struct ufs_power_parameter_element active_icc_levels_vccq[5];
+	/* Offset 42h: Maximum current for VCCQ2 (16 levels) */
+	struct ufs_power_parameter_element active_icc_levels_vccq2[5];
+} __packed;
+
+struct ufs_hba;
+
+int ufshcd_read_desc_param(struct ufs_hba *hba, enum desc_idn desc_id,
+			   int desc_index, u8 param_offset,
+			   u8 *param_read_buf, u8 param_size);
+void ufshcd_cache_flush(void *addr, unsigned long size);
+int ufshcd_query_flag(struct ufs_hba *hba, enum query_opcode opcode,
+		      enum flag_idn idn, bool *flag_res);
+int ufshcd_query_descriptor_retry(struct ufs_hba *hba, enum query_opcode opcode,
+				  enum desc_idn idn, u8 index,
+				  u8 selector, u8 *desc_buf, int *buf_len);
 #endif

-- 
2.43.0

