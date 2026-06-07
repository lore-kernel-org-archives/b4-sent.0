From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Sun, 07 Jun 2026 18:45:34 +0300
Subject: [PATCH v2 4/5] ufs: document the UFS command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260607-ufs_tool2-v2-4-f79ff26ab18c@mobileye.com>
References: <20260607-ufs_tool2-v2-0-f79ff26ab18c@mobileye.com>
In-Reply-To: <20260607-ufs_tool2-v2-0-f79ff26ab18c@mobileye.com>
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Michal Simek <michal.simek@amd.com>, Julien Stephan <jstephan@baylibre.com>, 
 Udit Kumar <u-kumar1@ti.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>, Jared McArthur <j-mcarthur@ti.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Dinesh Maniyam <dinesh.maniyam@altera.com>, 
 Heiko Schocher <hs@nabladev.com>, Simon Glass <sjg@chromium.org>, 
 briansune <briansune@gmail.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kory Maincent <kory.maincent@bootlin.com>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5620;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=UqfUn4vtl9eznAqacasc9WxEIng/kmK1nog/UheviOw=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJZI6RFUe+gFZxMT6550TVhjUorw9LgipNV/8H
 JNou3m3RLmJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiWSOgAKCRCfmumUluiO
 OVuTEAC+ALFbkN6a7dbT4nTletyrclbc7q1YeenaCI4uaQUwcbge8O1RnvdyYCvr7dj4G8E09v2
 DMUZqbGqX79Z7abjwszMhb3vUggNJQ6j6/LyXiH+mEURe6QnzZBJZJcrlEq5R/O2b3tiWeBbdUD
 EgsgqbsB9b/TnB6SyLOXJKLMazJzTdfV1ELWGWlfHy+huhNX/zlR29DaMPI1kxD8SBkx//mJ/+g
 k7NyvmvZ1os4oBkuoa1Edv6DLvzUkdMb4rcSvXSRcQ19ABzRTEIjl0W1aAQ0dbq2vZ3+dOUO+sM
 UTlbdbpW+t18D3DG6AOzuw7P6sjQ7vJvwTtsxzOiG/PZMarrU8qnWHKN/tnev8iRUZ9TqPhUCQ5
 /ewZCjdNSZrP7wperPl05SLXXQTI09zWY9k9G5XJWw9J/3Xmf9T/lhwYDA0KGCOr9cYzS3TbXLF
 8AG5xb/lBLZn1IPMwpeiyFgy8XhHHn/jABqrsHlZcc2jDH6MI2LxMxAzYzsH1H+PmmM+6RYsnMF
 sT5zfSkWKbWhSkQOtSUNS6Q/rpQymewZ75tuMGzqwUzHOU63dDT1rGpqFBiILtz4T4UZwFmQi94
 3jg7tjLJGxTvDtVFqLLuTTbQJHAAM0vDvTweP7wn2bDS7tP0AxdjNaCfP1AgHLPT4tLpIeZE6fx
 TJR1PWI+XXNjbOw==
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
 doc/usage/cmd/ufs.rst | 226 ++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 226 insertions(+)

diff --git a/doc/usage/cmd/ufs.rst b/doc/usage/cmd/ufs.rst
new file mode 100644
index 00000000000..1553bc28935
--- /dev/null
+++ b/doc/usage/cmd/ufs.rst
@@ -0,0 +1,226 @@
+.. SPDX-License-Identifier: GPL-2.0+
+
+ufs Tool
+========
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
+Query descriptors::
+
+    ufs query [lun] [idn]
+
+Descriptor IDs
+~~~~~~~~~~~~~~
+
+::
+
+    0x00  Device Descriptor
+    0x01  Configuration Descriptor
+    0x02  Unit Descriptor
+    0x07  Geometry Descriptor
+    0x08  Power Descriptor
+
+Configure a Logical Unit (LUN)
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+::
+
+    ufs set_lun <lun> <parameter> <value>
+
+Supported parameters::
+
+    lu_enable
+    boot_lun_id
+    lu_write_protect
+    memory_type
+    data_reliability
+    num_allocunits
+    logical_block_size
+    provisioning_type
+    context_capabilities
+    lu_num_write_booster_buffer_allocunits
+
+Modify Device Descriptor fields
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+::
+
+    ufs set_dev_desc <parameter> <value>
+
+Supported parameters::
+
+    descriptor_idn
+    device
+    device_class
+    device_sub_class
+    number_lu
+    boot_enable
+    descr_access_en
+    init_power_mode
+    high_priority_lun
+    secure_removal_type
+    initactive_icc_level
+    queue_depth
+    write_booster_buffer_preserve_user_space_en
+    write_booster_buffer_type
+    spec_version
+    manufacturer_id
+    periodic_rtc_update
+    device_version
+    psa_max_data_size
+    extended_ufs_features_support
+    num_shared_write_booster_buffer_allocunits
+
+Modify Configuration Descriptor fields
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+::
+
+    ufs set_cfg_desc <parameter> <value>
+
+Supported parameters::
+
+    length
+    descriptor_idn
+    conf_desc_continue
+    boot_enable
+    descr_access_en
+    initpower_mode
+    high_priority_lun
+    secure_removal_type
+    init_active_icc_level
+    periodic_rtc_update
+    reserved_HPB
+    rpmb_region_enable
+    rpmb_region1_size
+    rpmb_region2_size
+    rpmb_region3_size
+    write_booster_buffer_preserve_user_space_en
+    write_booster_buffer_type
+    num_shared_write_booster_buffer_allocunits
+
+Query UFS flags
+~~~~~~~~~~~~~~~
+
+::
+
+    ufs getflag <flag_name>
+
+Supported flags::
+
+    deviceinit
+    permanent_wpe
+    pwr_on_wpe
+    bkops_en
+    life_span_mode
+    purge_enable
+    fphy_resource_removal
+    busy_rtc
+    permanently_disable_fw_update
+    write_booster_en
+    wb_buf_flush_en
+    wb_buf_flush_h8
+
+Examples
+--------
+
+Create LUN 4::
+
+    ufs query 1 1
+    ufs set_lun 4 num_allocunits 100
+    ufs commit
+    scsi scan
+
+Update WriteBooster configuration::
+
+    ufs query 1 1
+    ufs set_cfg_desc num_shared_write_booster_buffer_allocunits 100000
+    ufs set_cfg_desc write_booster_buffer_type 1
+    ufs commit
+
+Clear all LUN configurations::
+
+    ufs clearall
+
+This command clears all configured LUNs and commits the change.
+
+Set HBA ID
+~~~~~~~~~~~~~~~
+
+::
+
+    ufs sethba <hbaid>
+
+Use an hba id differs from 0.
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
+1. Display the current Configuration Descriptor::
+
+       ufs query 1 1
+
+2. Load the configuration file into the Configuration Descriptor buffer
+   using XMODEM or TFTP::
+
+       loadx 0x8ffffce00
+
+   or::
+
+       tftpget 0x8ffffce00 luns.bin
+
+3. Commit the configuration to the UFS device::
+
+       ufs commit
+
+   The imported Configuration Descriptor is written to the device and
+   becomes active after the commit operation completes.

-- 
2.43.0

