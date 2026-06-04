From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Thu, 04 Jun 2026 14:25:54 +0300
Subject: [PATCH PATCHSET 6/6] ufs: doc/usage/cmd/ufs.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-ufs_tool-v1-6-741ed00232c0@mobileye.com>
References: <20260604-ufs_tool-v1-0-741ed00232c0@mobileye.com>
In-Reply-To: <20260604-ufs_tool-v1-0-741ed00232c0@mobileye.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Peng Fan <peng.fan@nxp.com>, Kory Maincent <kory.maincent@bootlin.com>, 
 Yao Zi <me@ziyao.cc>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Michal Simek <michal.simek@amd.com>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Jared McArthur <j-mcarthur@ti.com>, Shawn Lin <shawn.lin@rock-chips.com>, 
 Igor Belwon <igor.belwon@mentallysanemainliners.org>, 
 Tuyen Dang <tuyen.dang.xa@renesas.com>, Alexey Charkov <alchark@gmail.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5344;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=aYK6ZZSX72OkN7quuRhfm9mWdLZJuSfsa5D3xewp+Zk=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqIWDA+8z/Wkg1Ynl6qeA7WekjPR/KOhs7P5F2P
 tu5ckMzbGSJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiFgwAAKCRCfmumUluiO
 OeSqD/0cZuFChlVjhrrWfnsN04JgM4djQctOJomIXCvSmUjmi1ituKCQWRVODi9qerVDmV4q/c6
 c4SOrTzzrvZi3bLxoGeoQ/tJYQZWwbBSffNhLBiUZsHvaDjD77c1VVLZXVtYrN3qaCEwn98rSOo
 8BRuo1zp0a5uLXbqxnOmmZKcmdwmWuvxrOH6ZLWhj2vcE5kDJRlCc+fAV/rKaBbs0el14XdppIJ
 /PRNvPwJckdyuH7AJk4+ZzZHUX3AIY8Im1d6u6C6C+z5XWT8nMfbIf5wnIvWxi0etKDRdlji8kL
 ehyQzzjogDP2AG4F4qg/w/G0lQagIiOL7a/QRDVNA2agWexQ0hdIh4jXUgX331+QqwiH0/yZtm7
 AMi9zdCA6JNFOrtFvGc19eZvJrlw2z3niDQAOJV6v0wsZUd4zGzFWU+dvwpC6y3uPGGBMNqSw0j
 i0/BFwvk9fVGHDAuNuu0JY4nx9qNihJttBjIxCHb16v4V4JEsRO5pjqRf4cyv89Yt5SBF0/JOaZ
 SQR5m9E0bSjfdHAwHJ/HQj/RX0Qwo4IMLuh4EYC/gio/njokCmH5iBBqddBHRTB8j8wl9bWLLYh
 DpSp1rMgosWXLn25Og3AU60Gfo921yGtzlfpmsl6Wx99WXV7S7WiB6wbk+HQMPO+3Fr9keycfoa
 9c5Cse8iwU7FIQQ==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Documention of the ufs tool.

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 doc/usage/cmd/ufs.rst | 217 ++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 217 insertions(+)

diff --git a/doc/usage/cmd/ufs.rst b/doc/usage/cmd/ufs.rst
new file mode 100644
index 00000000000..a6faf4b1347
--- /dev/null
+++ b/doc/usage/cmd/ufs.rst
@@ -0,0 +1,217 @@
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
+    ufs set_lun 4 num_allocunits <size_in_alloc_units>
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

