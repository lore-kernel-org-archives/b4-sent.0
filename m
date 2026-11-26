From: Peder Bergan <peder.bergan@gmail.com>
Subject: [PATCH 0/3] drm/panic: Speed up QR code encoding
Date: Thu, 26 Nov 2026 17:53:14 +0100
Message-Id: <20261126-perf-drm-panic-qr-v1-0-51856937dc4d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPpjCGsC/1XMTQrCMBCG4auUWTvYBhPUq4iL/EzsCI1xUqVQe
 ncTXbl8hvneFQoJU4Fzt4LQmws/UsWw68CPNt0IOVSD6pUZBmUwk0QMMmG2iT0+BfXRmROFPh6
 0hrrLQpGXb/Ny/bm83J383ELtw9lC6MQmP7ZT4/4v2TBx8ZhomWHbPoSdYyOnAAAA
X-Change-ID: 20261126-perf-drm-panic-qr-58b69ed0f455
To: Jocelyn Falempe <jfalempe@redhat.com>, 
 Javier Martinez Canillas <javierm@redhat.com>
Cc: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 dri-devel@lists.freedesktop.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795711998; l=1688;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=iDsLMb9aE0AlmFCf+gA2dXKbpkU/dhpl3hq2AY5ctqI=;
 b=40xnObcbPohCg/rGboSbRgdZHBAKadpaSbTlyOBgw/YCPJSPXbZ6WunLCvCJWFT1bbaIPdlLl
 qv8dqwinY1KCL/FRNXVcX6qTtgl81Iyvns5c79/Zzh/SAemijqXyg3N
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DRM panic helper encodes kernel log data into a QR code. Speed up
encoding by searching alignment centers per axis, applying fixed mask 0
during data placement, and simplifying exponent reduction in
Reed-Solomon error correction.

I benchmarked the extracted encoder with Rust 1.100.0 on an x86-64
Ryzen 7 9800X3D. Across 12 paired warm runs per workload, median
version-40 encoding time fell from 1.778 ms to 0.277 ms with a
2,900-byte raw payload and from 1.782 ms to 0.284 ms with a URL and
a 2,800-byte payload encoded in numeric mode. Both workloads produced
identical QR images. The timings cover encoding only. Log collection,
compression and framebuffer drawing were outside the benchmark.

In the differential checks, each patch preserved the returned width
and all output bytes across 6,002 raw and URL test inputs. The mask
traversal check covered all 40 QR versions, including the remainder
modules.

I also ran the drm_panic_helper KUnit suite in x86-64 QEMU/KVM with
the QR URL empty and with a URL configured. Both runs passed all 45
checks, including 15 QR cases.

---
OpenAI Codex assisted with coding and testing.

---
Peder Bergan (3):
      drm/panic: Check QR alignment centers one axis at a time
      drm/panic: Apply the QR mask while drawing data modules
      drm/panic: Simplify QR error correction exponent reduction

 drivers/gpu/drm/drm_panic_helper_qr.rs | 59 +++++++++++++---------------------
 1 file changed, 23 insertions(+), 36 deletions(-)
---
base-commit: 5ce32a0c94a827ff44ee60898c28060714dcff75
change-id: 20261126-perf-drm-panic-qr-58b69ed0f455

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

