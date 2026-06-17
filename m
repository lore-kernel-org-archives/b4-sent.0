From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Wed, 17 Jun 2026 12:26:15 +0300
Subject: [PATCH v5 3/5] ufs: document the UFS command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-ufs_tool2-v5-3-1cf099f71111@mobileye.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=13671;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=8O8W4SkYl+2Hah2bAFLbjHSExRaTVu5gUFE7NUAsMto=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqMmhEg5nacLH/Cuu96RohV6dzmeCeikJR48T//
 KNYMadAHTWJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCajJoRAAKCRCfmumUluiO
 Ob6zD/9/1MIw7CHZaOR/CK/U3Uj0+HIHrgy1ibqAmB66zNr9I7uE6BjNKiNE804McQBjJwcuaNj
 lFMySIpgaJDVNoTqlKGNuyuSKkgQAaDdq9mcEpAcaAq4OOvm4iRAh9iaAMWG3jTqJEao7hsuVm7
 ozA9yClcEyijIWwuzOgdp8SQBdH/9Q7sU075mvC7cp/2OguMfMw9zEzPu3CwO0K40ByZeZfMyVQ
 cKZmG0JGas5sjKtpCNOVgYUZfTLF43YM3x7e8nnGdLuFC4Om1CH/J/gG4SxSFUG8CllOKeXI/Lf
 8biU513CSdwuFGyoGWiL7jWhpBtMXt6u4OKvLneyP6Ql3sWgyZb2tBISaUqasCdnVLxmyl6FKA9
 M4zRb4/eEHKcJ8xMhvFW27eKosJ+nFnWrWiiX7i8SiBf9DzifWh68YIdTcdZ74eSk5mkWkqhuNh
 thz9ajEFq3YwPL1aQvfQ9nCidFpljUy4qdGMrx3qwlLS/smF+EkRGFQvLult24ofJeNRNmoMX+3
 lCZLo8vRiyxdJHhBuH25nXeaIQgTPi0i7eRNHmGk4OnWbLZWxAN3DniOl7/nq6QvLTBvSTjrqB+
 IJYYyCCaJ7pJ4fut8OuZtpCGBwcRu9z2BVu6XqbEUHI65ofrGgerdp2dVc7Gy1oAr5+3h9gWbFB
 cgaYRFSky3aYWuA==
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
 doc/usage/cmd/ufs.rst | 499 ++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 499 insertions(+)

diff --git a/doc/usage/cmd/ufs.rst b/doc/usage/cmd/ufs.rst
new file mode 100644
index 00000000000..868761356cf
--- /dev/null
+++ b/doc/usage/cmd/ufs.rst
@@ -0,0 +1,499 @@
+.. SPDX-License-Identifier: GPL-2.0+
+
+.. index::
+        single: ufs (command)
+
+ufs command
+===========
+
+Synopsis
+--------
+
+::
+
+    ufs query <idn> [lun]
+    ufs set_cfg_desc <lun> <parameter> <value>
+    ufs get_cfg_desc
+    ufs get_flag <flag>
+    ufs set_hba <hbaid>
+    ufs init
+    ufs commit
+    ufs clearall
+    ufs luns
+    ufs set_lun <lun> <parm> <value>
+    ufs get_lun <lun>
+    ufs clear_lun
+
+Query Description
+------------------
+
+The ``ufs`` command is used to query, display and modify Universal Flash
+Storage (UFS) device configuration and descriptor information.
+
+The ``ufs query`` command displays UFS descriptors.
+
+::
+
+    ufs query <idn> [lun]
+
+    idn
+        Descriptor identifier.
+
+        ===== =================================
+        Value Descriptor
+        ===== =================================
+        0x00  Device Descriptor
+        0x01  Configuration Descriptor
+        0x02  Unit Descriptor
+        0x07  Geometry Descriptor
+        0x08  Power Descriptor
+        ===== =================================
+
+
+       LUN Required only for Unit Descriptor (IDN 0x02).
+
+
+Descriptor Information
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+Queries for descriptors always require direct access to the controller.
+
+
+Device Descriptor (IDN 0x00)
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+The Device Descriptor contains general information about the UFS device,
+including:
+
+* Device identification
+* Manufacturer information
+* Product name and revision
+* Number of logical units
+* Queue depth
+* Boot configuration
+* WriteBooster capabilities
+* Supported UFS features
+ ...
+
+Example:
+
+::
+
+    => ufs query 0
+
+          Name | Value | Description
+          ---------------------------
+          Length | 0x59
+          DescriptorIdn | 0x0
+          Device | 0x0
+          DeviceClass | 0x0
+          DeviceSubClass | 0x0
+          protocol | 0x0
+          NumberLu | 0
+          NumberWLu | 4
+          BootEnable | 0x1
+          DescrAccessEn | 0x1
+
+      ...
+
+
+Geometry Descriptor (IDN 0x07)
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+The Geometry Descriptor provides information about the physical layout
+and capabilities of the device, including:
+
+* Total raw device capacity
+* Maximum number of logical units
+* Allocation unit size
+* Segment size
+* Supported memory types
+* RPMB capabilities
+* Secure removal support
+* WriteBooster limits
+
+Example:
+
+::
+
+    => ufs query 7
+
+        Name   | Value              | Description
+        ---------------------------------------------
+        Length | 0x57  | Size of descriptor
+        DescriptorIdn   | 0x7 | geometry Descriptor ID
+        MediaTechnology | 0x0 | Reserved (00h)
+        TotalRawDeviceCapacity | 119 GB
+        MaxNumberLu | 1 | Max LUs (00h: 8, 01h: 32)
+        SegmentSize | 8192 | Segment size (512B units)
+        AllocationunitSize | 1 | Alloc unit size (in segments)
+   ...
+
+
+Unit Descriptor (IDN 0x02)
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+The Unit Descriptor contains information about a specific Logical Unit
+(LUN), including:
+
+* LUN enable state
+* Boot LUN assignment
+* Write protection configuration
+* Memory type
+* Logical block size
+* Provisioning type
+* Data reliability settings
+* WriteBooster allocation
+
+Example:
+
+::
+
+    => ufs query 2 3
+
+        --- UFS unit Descriptor (IDN: 02h) ---
+        Name   | Value              | Description
+        ---------------------------------------------
+        Length | 45 | Size of descriptor
+        DescriptorIdn | 0x2 | unit Descriptor ID
+        BunitIndex  | 0x3 | Logical unit Index
+        luEnable | 0x0 | LU Enabled (01h) or Disabled (00h)
+        BootLunId | 0x0| Boot LU ID (01h: A, 02h: B
+        luWriteProtect | 0x0 | WP (01h: power-on, 02h: Perm)
+        luQueueDepth | 0x0 | Queue depth (0 if shared)
+    ...
+
+
+Power Descriptor (IDN 0x08)
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+Queries command of Power IDN.
+
+::
+
+  => ufs query 8
+        --- UFS power Parameters Descriptor (IDN: 08h) ---
+
+        Descriptor Length: 0x62 (98 bytes)
+        Descriptor IDN:    0x8
+
+        Level | VCC Current | VCCQ Current | VCCQ2 Current
+        --------------------------------------------------
+        0       | 0 n_a      | 0 n_a       | 0 n_a
+        1       | 0 n_a      | 0 n_a       | 0 n_a
+        2       | 0 n_a      | 0 n_a       | 0 n_a
+        3       | 0 n_a      | 0 n_a       | 0 n_a
+        4       | 0 n_a      | 0 n_a       | 0 n_a
+
+
+
+Configuration Descriptor (IDN 0x01)
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+The Configuration Descriptor defines the layout and configuration
+of all Logical Units on the device. This query reads the descriptor
+from the controller and caches it. The cached descriptor is used
+exclusively by configuration commands,
+including get_lun, clear_lun, set_cfg_desc, get_cfg_desc,
+set_lun, clear_lun, get_lun, and commit.
+The ufs command does not use ufs staging, because in some extreme
+cases (ex. P/E consumed) staging fails.
+
+It contains:
+
+* Boot configuration
+* RPMB configuration
+* WriteBooster settings
+* Logical Unit definitions
+* Allocation unit assignments
+
+etc..
+
+Example:
+
+::
+
+    => ufs query 1
+        Config Descriptor: (0x00000008ffff6628)
+        Length                          : 0x0e6
+        DescriptorIdn                   : 0x01
+        ConfDescContinue                : 0x00
+        BootEnable                      : 0x01
+        DescrAccess_en                   : 0x01
+        InitPowerMode                   : 0x01
+        HighPriorityLun                 : 0x07f
+        SecureRemovalType               : 0x02
+        InitActiveIccLevel              : 0x01
+        PeriodicRtcUpdate               : 0x00
+        Reserved_HPB                    : 0x00
+        RpmbRegionEnable                : 0x00
+        RpmbRegion1Size                 : 0x00
+        RpmbRegion2Size                 : 0x00
+        RpmbRegion3Size                 : 0x00
+        WriteBoosterBufferPreserveUserSpaceEN : 0x01
+        WriteBoosterBufferType           : 0x00
+        NumSharedWriteBoosterBufferAllocUnits : 0x00
+        -------------------------------------------------
+        LUN 0 Capacity 16 MB
+        Name  | Value      | Description
+        -------------------------------------------------
+        LuEnable  | 0x1  | Enabled, 00h: Disabled
+        BootLunId | 0x1  | Boot LU A, 02h: Boot LU B
+        LuWriteProtect | 0x0 | power-on, 02h: Permanent
+        MemoryType| 0x3 | Normal, 01h: System Code
+        NumAllocunits | 12 | Number of Allocation units for LU
+        DataReliability | 0x1 | power failure protection
+        LogicalBlockSize | 0xc | Block size exponent (Min: 0Ch)
+        ProvisioningType | 0x0 | Full, 02h/03h: Thin
+    ...
+
+
+Examining a LUN
+----------------------
+
+The command get_lun reports a lun from the Cached Configuration descriptor.
+
+Example:
+
+::
+
+
+    => ufs get_lun 1
+
+        LuEnable  | 0x1  | Enabled, 00h: Disabled
+        BootLunId | 0x2  | Boot LU A, 02h: Boot LU B
+        LuWriteProtect | 0x0 | power-on, 02h: Permanent
+        MemoryType| 0x3 | Normal, 01h: System Code
+        NumAllocunits | 12 | Number of Allocation units for LU
+        DataReliability | 0x1 | power failure protection
+        LogicalBlockSize | 0xc | Block size exponent (Min: 0Ch)
+        ProvisioningType | 0x0 | Full, 02h/03h: Thin
+        ContextCapabilities     | 0x0 | LU Context support/multipliers
+        LuNumWriteBoosterBufferAllocunits| 16777220 | WB Buffer size
+
+
+Creating a LUN
+----------------------
+
+The command set_lun updates a LUN configuration. It does not write the
+LUN to the controller.
+A Lun must be enabled for it become a scsi disk.
+To write to the controller issue the command ufs commmit.
+
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
+Example:
+
+::
+
+    => ufs set_lun 0 num_allocunits 4
+
+        LuEnable  | 0x0  | Enabled, 00h: Disabled
+        BootLunId | 0x1  | Boot LU A, 02h: Boot LU B
+        LuWriteProtect | 0x0 | power-on, 02h: Permanent
+        MemoryType| 0x3 | Normal, 01h: System Code
+        NumAllocunits | 4 | Number of Allocation units for LU
+        DataReliability | 0x1 | power failure protection
+        LogicalBlockSize | 0xc | Block size exponent (Min: 0Ch)
+        ProvisioningType | 0x0 | Full, 02h/03h: Thin
+        ContextCapabilities     | 0x0 | LU Context support/multipliers
+        LuNumWriteBoosterBufferAllocunits| 16908291 | WB Buffer size
+
+
+Getting A flag
+------------------
+The command get_flag retrieves a flag value..
+    ufs get_flag <parameter>
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
+Example:
+
+::
+
+    => ufs getflag bkops_en
+        bkops_en = 1
+
+
+Configuration Descriptor
+-----------------------------------------
+    ufs set_cfg_desc [parameter] [value]
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
+Example:
+
+::
+
+    => ufs set_cfg_desc num_shared_write_booster_buffer_allocunits 100
+
+
+Luns Info
+-----------------------------
+
+The command ufs luns prints the current enabled LUNs stored in the controller.
+
+Example:
+
+::
+
+    => ufs luns
+
+
+        | LUN 0      | LUN 1       | LUN 2       | LUN 3     | LUN 4      |
+        | 3 MB       | 10 MB       | 1 MB        | 2312 MB   | 114364 MB  |
+
+
+Clear all LUNs
+-----------------------------
+
+
+The command ufs clearall, clears all LUNs, and auto-commit the zeroed LUNs
+to the controller.
+
+Clear LUN
+-----------------------------
+
+
+The command ufs clear_lun,
+set all fields to zero other than the block size.
+The lun is cleared in the cached configuration descriptor.
+
+Delete LUN
+-----------------------------
+
+To delete a lun use : ufs set_lun <lun> lu_enable 0
+and then ufs commit.
+
+
+Set HBA ID
+----------------------
+
+
+    ufs set_hba [hbaid]
+
+Use an hba id differs from 0.
+
+
+Init
+----------------------
+
+        ufs init
+
+Initialize the HBA controller. This command is not necessary and
+used for debugging.
+All other commands initializes the HBA controller automatically
+if required.
+
+Commit
+----------------------
+
+        ufs commit
+
+The command ufs commit writes the current configuration descriptor
+to the controller.  In case the configuration is incorrect, the commit
+will fail. Ufs commit is usually done after creating a lun.
+
+Provisioning workflow
+----------------------
+
+Source system
+~~~~~~~~~~~~~~~
+
+1. Display the Configuration Descriptor::
+
+        ufs query 1
+
+::
+
+    => ufs query 1
+        Config Descriptor: (0x00000008ffff6628)
+     ...
+
+The output includes the Configuration Descriptor address and size.
+
+2. Save the Configuration Descriptor to a file::
+
+        tftpput <cfg_desc_addr> <size> <filename>
+
+   Example::
+
+        tftpput 0x00000008ffff6628 0xe6 luns.bin
+
+This exports the current UFS configuration, including LUN settings.
+
+Target system
+^^^^^^^^^^^^^
+
+
+1. Load the configuration file into the Configuration Descriptor buffer
+   using XMODEM or TFTP:
+
+
+::
+
+        loadx
+        ## Ready for binary (xmodem) download to 0x860000000 at 921600 bps...
+
+   or:
+
+        tftpget luns.bin
+
+
+3. Overwrite
+
+  ::
+
+        ufs provision 0x860000000
+
+To overwrite luns.bin over the Configuration descriptor.
+
+4. Commit the configuration to the UFS device:
+
+::
+
+        ufs commit
+
+The imported Configuration Descriptor is written to the device and
+becomes active after the commit operation completes.

-- 
2.43.0

