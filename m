From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Mon, 08 Jun 2026 13:33:28 +0300
Subject: [PATCH v3 4/5] ufs: document the UFS command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-ufs_tool2-v3-4-a9f181e86229@mobileye.com>
References: <20260608-ufs_tool2-v3-0-a9f181e86229@mobileye.com>
In-Reply-To: <20260608-ufs_tool2-v3-0-a9f181e86229@mobileye.com>
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Tawfik Bayouk <tawfik.bayouk@mobileye.com>, 
 Vladimir Kondratiev <vladimir.Kondratiev@mobileye.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5337;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=aAVR8Qe3cCUlFSZF2hSKkmI5T2PpvW1rEMaR2yGcr44=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJpqWSdQ4c+nhBfReQW4eu47rYMdWTmcGS2VPT
 DCFiLigI9OJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiaalgAKCRCfmumUluiO
 OeD9D/0X7ZUfhdH1yUVRizJ9Zvhjty5DKMJpIZsLUCnfAT2xEV2EaAfWV8zxWEkXjPFtYXoWGRK
 GRTE9V3ghFmrrGv14KHvyoKn1ZZLYf0HaJOm++kgK3huUwt1GWc7lgmDoLOshALPLYBQ5W7nP5y
 4s0gMeJxc++7fthRmKVvGIp/br7KwLNcO+okoxFALIijZqG86fWK09Ly0kC2zNKxuwoh+Qq1NOB
 3hdgrKzrNHThXjQ4UMBEwHS4gZX/6ZDEDwwAwjqiCawD6w/EQ++BoZpmdKnq/sSN3WBFhvkBe0F
 IrPkzMDZfxwrPm0sHe3h6YJjS1aRQ4HN6FsI1UTlFWXy+6ivz11SqKPksDGjTmbrYWhuUQY9mOG
 6hdbMn8phiUpXWCZOwC1wcs0vM64uelGEny5A3/9yVMnMhQDlgeKGxIvJ0YI9zPGKz2qz5UqDES
 u9cpF9c2bmwarPn+0ajyoerCCmmVykjVM4mRNryLO0OrF0jkHU6BUHKFeDFuBX2VjymK8YQlHcF
 wjtUiABbe9BobaTUhPPTznqH/oOYUN/O8D4rnTnsajWk/2V30ovcdu1i1rCj3LGGmKfoMrd2J6D
 kaI64vVyt+xwfQn0ITOtyCVBkByBoH2oWuq/k8Wuk+0psY+tW/yUEmdTo5+t01BzUZSES3AflUZ
 FPU6fVSJI4+bjnw==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

    Add documentation for the UFS command-line interface.

    The document describes the available UFS subcommands and their usage,
    and provides a complete command-line reference for configuring and
    managing UFS devices.

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 doc/usage/cmd/ufs.rst | 202 ++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 202 insertions(+)

diff --git a/doc/usage/cmd/ufs.rst b/doc/usage/cmd/ufs.rst
new file mode 100644
index 00000000000..7bc2296ec17
--- /dev/null
+++ b/doc/usage/cmd/ufs.rst
@@ -0,0 +1,202 @@
+.. SPDX-License-Identifier: GPL-2.0+
+
+ufs command line
+================
+
+The ``ufs`` tool provides utilities for querying, displaying, and modifying
+UFS device configuration and descriptor information.
+
+Features
+--------
+
+* Query and display Device, Geometry, Unit, Configuration, and Power
+  Descriptors.
+* Display LUN configuration and calculated capacities.
+* Modify LUN, Configuration, and Device Descriptor fields.
+* Configure WriteBooster-related parameters.
+* Query common UFS runtime flags.
+* Commit configuration changes or clear all LUN configurations.
+* Decode and format descriptor contents for easier debugging.
+* Provision UFS devices using exported Configuration Descriptors.
+
+The UFS tool header definitions are based on the JEDEC JESD220E
+*Universal Flash Storage (UFS) Version 3.1* specification.
+
+Usage
+-----
+
+Query descriptors
+
+    ufs query [lun] [idn]
+
+Descriptor IDs
+    * 0x00  Device Descriptor.
+    * 0x01  Configuration Descriptor
+    * 0x02  Unit Descriptor
+    * 0x07  Geometry Descriptor
+    * 0x08  Power Descriptor
+
+Only UnitDescriptor requires a valid LUN id. Other descriptors
+disregard the LUN id.
+
+Example:
+
+
+
+
+Configure a Logical Unit (LUN)
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+    ufs set_lun <lun> <parameter> <value>
+
+Supported parameters
+    * lu_enable
+    * boot_lun_id
+    * lu_write_protect
+    * memory_type
+    * data_reliability
+    * num_allocunits
+    * logical_block_size
+    * provisioning_type
+    * context_capabilities
+    * lu_num_write_booster_buffer_allocunits
+
+Modify Configuration Descriptor fields
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+    ufs set_cfg_desc <parameter> <value>
+
+Supported parameters::
+    * length
+    * descriptor_idn
+    * conf_desc_continue
+    * boot_enable
+    * descr_access_en
+    * initpower_mode
+    * high_priority_lun
+    * secure_removal_type
+    * init_active_icc_level
+    * periodic_rtc_update
+    * reserved_HPB
+    * rpmb_region_enable
+    * rpmb_region1_size
+    * rpmb_region2_size
+    * rpmb_region3_size
+    * write_booster_buffer_preserve_user_space_en
+    * write_booster_buffer_type
+    * num_shared_write_booster_buffer_allocunits
+
+Query UFS flags
+~~~~~~~~~~~~~~~
+
+    ufs getflag <flag_name>
+
+Supported flags::
+    * deviceinit
+    * permanent_wpe
+    * pwr_on_wpe
+    * bkops_en
+    * life_span_mode
+    * purge_enable
+    * fphy_resource_removal
+    * busy_rtc
+    * permanently_disable_fw_update
+    * write_booster_en
+    * wb_buf_flush_en
+    * wb_buf_flush_h8
+
+Examples
+--------
+
+Create LUN 4 of size of 100xAllocUnitSize
+
+      ufs query 1 1
+
+      ufs set_lun 4 num_allocunits 100
+
+      ufs commit
+
+      scsi scan
+
+Update WriteBooster configuration
+
+      ufs query 1 1
+
+      ufs set_cfg_desc num_shared_write_booster_buffer_allocunits 100000
+
+      ufs set_cfg_desc write_booster_buffer_type 1
+
+      ufs commit
+
+Clear all LUN configurations
+    * ufs clearall
+
+This command clears all configured LUNs and commits the change.
+
+Set HBA ID
+~~~~~~~~~~~~~~~
+
+    ufs sethba <hbaid>
+
+Use an hba id differs from 0.
+
+
+Init
+~~~~~
+
+    ufs init
+
+Initialize the HBA. This command is not necessary and used for debugging.
+All other commands will initialize automatically if required.
+
+
+Provisioning
+------------
+
+To simplify UFS provisioning, the tool displays the memory address and
+size of the Configuration Descriptor (IDN 0x01). This allows the
+descriptor to be exported from one system and imported on another.
+
+Provisioning workflow
+~~~~~~~~~~~~~~~~~~~~~
+
+Source system
+^^^^^^^^^^^^^
+
+1. Display the Configuration Descriptor::
+
+       ufs query 1 1
+
+   The output includes the Configuration Descriptor address and size.
+
+2. Save the Configuration Descriptor to a file::
+
+       tftpput <cfg_desc_addr> <size> <filename>
+
+   Example::
+
+       tftpput 0x8ffffc610 0xe6 luns.bin
+
+   This exports the current UFS configuration, including LUN settings.
+
+Target system
+^^^^^^^^^^^^^
+
+1. Display the current Configuration Descriptor:
+
+         ufs query 1 1
+
+2. Load the configuration file into the Configuration Descriptor buffer
+   using XMODEM or TFTP:
+
+       loadx 0x8ffffce00
+
+   or:
+
+       tftpget 0x8ffffce00 luns.bin
+
+3. Commit the configuration to the UFS device:
+
+       ufs commit
+
+   The imported Configuration Descriptor is written to the device and
+   becomes active after the commit operation completes.

-- 
2.43.0

