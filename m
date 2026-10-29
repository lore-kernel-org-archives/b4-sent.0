From: Jacob Lefkowitz <jlefkowi@akamai.com>
Subject: [PATCH 0/2] perf jevents: Add IOMMU PTW & device entry metrics
Date: Thu, 29 Oct 2026 19:05:49 +0000
Message-Id: <20261029-perf-tools-next-v1-0-a75a2b64a15e@akamai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avIrBvwJ0S6SrSIHGsgVFQiiO6et
 PwW7z1QqTBVmMQDhS6unGKHGgRsxxp3QvbdoKW2SmqHmUrAltJZMdLd0AWv/GiMUXaFXuVCge/
 /OC/v+wF/0kB8YQAAAA==
X-Change-ID: 20261028-perf-tools-next-8fd1d433316a
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Arnaldo Carvalho de Melo <acme@kernel.org>, 
 Namhyung Kim <namhyung@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>, 
 Jiri Olsa <jolsa@kernel.org>, Ian Rogers <irogers@google.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 James Clark <james.clark@linaro.org>
Cc: linux-perf-users@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ben Chaney <bchaney@akamai.com>, Matt Pelland <mpelland@akamai.com>, 
 Jacob Lefkowitz <jlefkowi@akamai.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1370; i=jlefkowi@akamai.com;
 h=from:subject:message-id; bh=9W/7zSoftzSW5mCuATcSpLhTLtAaT6I/Mh4CFqig25w=;
 b=owEBbQKS/ZANAwAKAdLKfgzjwTS1AcsmYgBq45kgZpFbvA6GVbT+n9Qw6F1Ls6vUDYXekCgN9
 hINXOkM2XeJAjMEAAEKAB0WIQQKFmVpIhg7hFI7scTSyn4M48E0tQUCauOZIAAKCRDSyn4M48E0
 tSzXEAC4mq191t8r5p0TM73BaVqAZBdeswKU93lCq78nfvzsw7XwUeMm2HpZiHAS/0rK9sOHDXx
 vfBbuKWCy+QSZFtkc8qm0meHnjb95LO0dD4G3E1qogF16hJ9suDLyD9h+tw4nnMazslmSpM/5X2
 trjfp9yEG8Is75WjlRDXn48E1HscT29gmp//ziK2+Gzx90IBOTiyMmIkNIZpaf5JcoMUmt1Jar3
 ZK1rHwODaaukrGFHUzw3Yqw1f9xGUGZqq9G7FhHPtL53lx12yJx+VOZigDRKu8mz6g8+tN82ysY
 lsIIYaK7EFTLaRD8+ATRdK4P1HSeFmVuIyOpXVW37KVkZIYWKzpCUo3pWXdmkc5DDiCyuhMUVW4
 fk6wPfd0vEgisRx0wxSY7vF6nxbn57aNqeXZRaiW6E8Qn2F4nvEj0Of+e16oIlunbGls9dbqDJH
 ge3u3rlG7XMvfaS1RZLlnwLYgeiUQT5nc7wxB1P3jZsSbwR/EfVuVZAXhxEmF2OaqC+2Vs2u+M9
 k7VyWnoyj6KU0HhNTt0VUJz8AFG+FXXfGGuWeeE9aE7CML6hfUJncOXb8MlAQhE0+7+1ND9LSNf
 TV6RfXSU5oDySHBuxKtg9K7sBzmAH8B+okx/GWV9Yl03q3d6HXwHlSpfmdf29YRQUy0rLjZtD4A
 PiLqHBVfBvMJKHw==
X-Developer-Key: i=jlefkowi@akamai.com; a=openpgp;
 fpr=0A16656922183B84523BB1C4D2CA7E0CE3C134B5
X-Endpoint-Received: by B4 Relay for jlefkowi@akamai.com/default with auth_id=1357
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds AMD specific metrics for the IOMMU with respect to page table
walks and device table entires. The metrics cover ratios, rates, and
percentages with respect to any event which might be triggered during
a page table walk or device table entry lookup.

The metrics target Zen 2+ processors and use the standard amd_iommu
PMU events. They have been tested with a benchmark C program that
purposefully thrashed the TLB as well as with 'sleep 10'; both of
which work as expected.

The changes are split into two patches:
1. perf jevents: add iommu page table walk metrics
2. perf jevents: add amd specific device table entry metrics

The specific metris added are:
- lpm_iommu_dte_miss_rate
- lpm_iommu_dte_lookups
- lpm_iommu_ptw_reads_per_tlb_miss
- lpm_iommu_ptw_nested_read_ratio
- lpm_iommu_ptw_guest_read_ratio
- lpm_iommu_trans_per_sec

Signed-off-by: Jacob Lefkowitz <jlefkowi@akamai.com>
---
Jacob Lefkowitz (2):
      perf jevents: add iommu page table walk metrics
      perf jevents: add amd specific device table entry metrics

 tools/perf/pmu-events/amd_metrics.py | 81 +++++++++++++++++++++++++++++++++++-
 1 file changed, 80 insertions(+), 1 deletion(-)
---
base-commit: 1c90f0a3c8a1c4e38f9edd97af9e20848805a7fb
change-id: 20261028-perf-tools-next-8fd1d433316a

Best regards,
-- 
Jacob Lefkowitz <jlefkowi@akamai.com>

