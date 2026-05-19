From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Tue, 19 May 2026 11:45:52 +0530
Subject: [PATCH 02/15] accel/qda: Add QDA driver documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260519-qda-series-v1-2-b2d984c297f8@oss.qualcomm.com>
References: <20260519-qda-series-v1-0-b2d984c297f8@oss.qualcomm.com>
In-Reply-To: <20260519-qda-series-v1-0-b2d984c297f8@oss.qualcomm.com>
To: Oded Gabbay <ogabbay@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>
Cc: Bharath Kumar <quic_bkumar@quicinc.com>, 
 Chenna Kesava Raju <quic_chennak@quicinc.com>, srini@kernel.org, 
 dmitry.baryshkov@oss.qualcomm.com, andersson@kernel.org, 
 konradybcio@kernel.org, robin.clark@oss.qualcomm.com, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-doc@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 iommu@lists.linux.dev, linux-media@vger.kernel.org, 
 linaro-mm-sig@lists.linaro.org, 
 Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779171352; l=8323;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=6Ut+34eLykJ4L+9Idk831LtrZQVaIxX8yeHZTndv5yk=;
 b=ChlRG44v0dkte4eiD2TLJwERl6p5fUYBHWR57I8uXa8FgTV4quP09FaShlwYSDX68z86XtQtJ
 brBZ02MCA/8C2OXr7jzkQ67XRyf0yy4V83vbZKtPUXAaSt01JnuxBIA
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for the Qualcomm DSP Accelerator (QDA) driver under
Documentation/accel/qda/. The documentation covers the driver
architecture, GEM-based buffer management, IOMMU context bank
isolation, and the RPMsg transport layer.

The user-space API section describes the DRM IOCTLs for session
management, GEM buffer allocation, and remote procedure invocation via
the FastRPC protocol, along with a typical application lifecycle
example. Sections for dynamic debug and basic testing are also
included.

Wire the new documentation into the Compute Accelerators index at
Documentation/accel/index.rst.

Assisted-by: Claude:claude-4-6-sonnet
Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
 Documentation/accel/index.rst     |   1 +
 Documentation/accel/qda/index.rst |  13 ++++
 Documentation/accel/qda/qda.rst   | 146 ++++++++++++++++++++++++++++++++++++++
 3 files changed, 160 insertions(+)

diff --git a/Documentation/accel/index.rst b/Documentation/accel/index.rst
index cbc7d4c3876a..5901ea7f784c 100644
--- a/Documentation/accel/index.rst
+++ b/Documentation/accel/index.rst
@@ -10,4 +10,5 @@ Compute Accelerators
    introduction
    amdxdna/index
    qaic/index
+   qda/index
    rocket/index
diff --git a/Documentation/accel/qda/index.rst b/Documentation/accel/qda/index.rst
new file mode 100644
index 000000000000..013400cf9c25
--- /dev/null
+++ b/Documentation/accel/qda/index.rst
@@ -0,0 +1,13 @@
+.. SPDX-License-Identifier: GPL-2.0-only
+
+==================================
+accel/qda Qualcomm DSP Accelerator
+==================================
+
+The QDA driver provides a DRM accel based interface for Qualcomm DSP offload.
+It uses the FastRPC protocol and integrates with DRM and GEM infrastructure
+for device and buffer management.
+
+.. toctree::
+
+   qda
diff --git a/Documentation/accel/qda/qda.rst b/Documentation/accel/qda/qda.rst
new file mode 100644
index 000000000000..9f49af6e6acc
--- /dev/null
+++ b/Documentation/accel/qda/qda.rst
@@ -0,0 +1,146 @@
+.. SPDX-License-Identifier: GPL-2.0-only
+
+=====================================
+Qualcomm DSP Accelerator (QDA) Driver
+=====================================
+
+Introduction
+============
+
+The QDA driver is a DRM accel driver for Qualcomm's DSPs. It provides a
+DRM accel based interface for Qualcomm DSP offload, supporting workloads
+such as AI inference, computer vision, audio processing, and sensor offload
+on Qualcomm SoCs. It uses the FastRPC protocol and integrates with DRM and
+GEM infrastructure for device and buffer management.
+
+Key Features
+============
+
+*   **DRM accel Interface**: Exposes a standard character device node
+    (e.g., ``/dev/accel/accel0``) via the DRM accel subsystem.
+*   **FastRPC Protocol**: Implements the FastRPC protocol for communication
+    between the application processor and the DSP.
+*   **GEM Buffer Management**: Uses the DRM GEM interface for buffer
+    allocation, lifecycle management, and DMA-BUF import/export.
+*   **IOMMU Isolation**: Uses IOMMU context banks to enforce memory isolation
+    between different DSP user sessions.
+*   **Modular Design**: Clean separation between the core DRM logic, the
+    memory manager, and the RPMsg-based transport layer.
+
+Architecture
+============
+
+The QDA driver consists of several functional blocks:
+
+1.  **Core Driver (``qda_drv``)**: Manages device registration, file operations,
+    and DRM accel integration.
+2.  **Memory Manager (``qda_memory_manager``)**: A flexible memory management
+    layer that handles IOMMU context banks. It supports pluggable backends
+    (such as DMA-coherent) to adapt to different SoC memory architectures.
+3.  **GEM Subsystem**: Implements the DRM GEM interface for buffer management:
+
+    * **``qda_gem``**: Core GEM object management, including allocation, mmap
+      operations, and buffer lifecycle management.
+    * **``qda_prime``**: PRIME import functionality for DMA-BUF interoperability
+      with other kernel subsystems.
+
+4.  **Transport Layer (``qda_rpmsg``)**: Abstraction over the RPMsg framework
+    to handle low-level message passing with the DSP firmware.
+5.  **Compute Bus (``qda_compute_bus``)**: A custom virtual bus used to
+    enumerate and manage the specific compute context banks defined in the
+    device tree. The bus was introduced because IOMMU context banks (CBs) are
+    synthetic constructs — not real platform devices — making a platform driver
+    an incorrect abstraction for them. The earlier platform-driver approach also
+    had a race condition: device nodes were created before the RPMsg channel
+    resources were fully initialized, and because ``probe`` runs asynchronously,
+    applications could open a CB device and attempt to start a session before
+    the underlying transport was ready. The compute bus makes CB lifetime
+    explicitly subordinate to the parent QDA device, closing that window.
+6.  **FastRPC Core (``qda_fastrpc``)**: Implements the protocol logic for
+    marshalling arguments and handling remote invocations.
+
+User-Space API
+==============
+
+The driver exposes a set of DRM-compliant IOCTLs:
+
+*   ``DRM_IOCTL_QDA_QUERY``: Query DSP type (e.g., "cdsp", "adsp")
+    and capabilities.
+*   ``DRM_IOCTL_QDA_REMOTE_SESSION_CREATE``: Initialize a new process context
+    on the DSP.
+*   ``DRM_IOCTL_QDA_REMOTE_INVOKE``: Submit a remote method invocation (the
+    primary execution unit).
+*   ``DRM_IOCTL_QDA_GEM_CREATE``: Allocate a GEM buffer object for DSP usage.
+*   ``DRM_IOCTL_QDA_GEM_MMAP_OFFSET``: Retrieve mmap offsets for memory mapping.
+*   ``DRM_IOCTL_QDA_REMOTE_MAP`` / ``DRM_IOCTL_QDA_REMOTE_MUNMAP``: Map or unmap
+    buffers into the DSP's virtual address space. Each accepts a ``request``
+    field selecting between a legacy operation (``QDA_MAP_REQUEST_LEGACY`` /
+    ``QDA_MUNMAP_REQUEST_LEGACY``) and an attribute-based operation
+    (``QDA_MAP_REQUEST_ATTR`` / ``QDA_MUNMAP_REQUEST_ATTR``).
+
+Usage Example
+=============
+
+A typical lifecycle for a user-space application:
+
+1.  **Discovery**: Open ``/dev/accel/accel*`` and use
+    ``DRM_IOCTL_QDA_QUERY`` to identify the DSP domain served by that
+    device node.
+2.  **Initialization**: Call ``DRM_IOCTL_QDA_REMOTE_SESSION_CREATE`` to
+    establish a session and create a process context on the DSP.
+3.  **Memory**: Allocate buffers via ``DRM_IOCTL_QDA_GEM_CREATE`` or import
+    DMA-BUFs (PRIME fd) from other drivers using ``DRM_IOCTL_PRIME_FD_TO_HANDLE``.
+4.  **Execution**: Use ``DRM_IOCTL_QDA_REMOTE_INVOKE`` to pass arguments and
+    execute functions on the DSP.
+5.  **Cleanup**: Close file descriptors to automatically release resources and
+    detach the session.
+
+Internal Implementation
+=======================
+
+Memory Management
+-----------------
+The driver's memory manager creates virtual "IOMMU devices" that map to
+hardware context banks. This allows the driver to manage multiple isolated
+address spaces. The implementation uses a DMA-coherent backend to ensure data consistency
+between the CPU and DSP without manual cache maintenance in most cases.
+
+Debugging
+=========
+The driver includes extensive dynamic debug support. Enable it via the
+kernel's dynamic debug control:
+
+.. code-block:: bash
+
+    echo "file drivers/accel/qda/* +p" > /sys/kernel/debug/dynamic_debug/control
+
+Testing
+=======
+The QDA driver can be exercised using the ``fastrpc_test`` utility from the
+FastRPC userspace library. Run the test application:
+
+.. code-block:: bash
+
+    fastrpc_test -d 3 -U 1 -t linux -a v68
+
+**Options**
+
+``-d domain``
+    Select the DSP domain to run on:
+
+    * ``0`` — ADSP
+    * ``1`` — MDSP
+    * ``2`` — SDSP
+    * ``3`` — CDSP *(default on targets with CDSP)*
+
+``-U unsigned_PD``
+    Select signed or unsigned protection domain:
+
+    * ``0`` — signed PD
+    * ``1`` — unsigned PD *(default)*
+
+``-t target``
+    Target platform: ``android`` or ``linux`` *(default: linux)*
+
+``-a arch_version``
+    DSP architecture version, e.g. ``v68``, ``v75`` *(default: v68)*

-- 
2.34.1

