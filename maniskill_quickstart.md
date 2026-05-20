# ManiSkill Quickstart — Robotic Arm Simulation Guide

> **Project context:** This document is derived from the `quickstart (1)(1).ipynb` notebook used as the robotic arm simulation component of the Atlas AGV project. It covers environment setup, CPU/GPU simulation, rendering, GPU-parallel environments, teleoperation, robot visualisation, and motion planning using the [ManiSkill](https://maniskill.readthedocs.io/en/latest/) framework.

---

## Setup Code

Before running any cells, switch the Colab runtime to a **GPU** environment:  
*Runtime → Change Runtime Type → GPU (T4 recommended).*

The block below installs all dependencies. ManiSkill requires only two pip packages (`mani_skill` and `torch`) plus the Vulkan graphics driver.

```bash
# Set up Vulkan ICD files
mkdir -p /usr/share/vulkan/icd.d
wget -q https://raw.githubusercontent.com/haosulab/ManiSkill/main/docker/nvidia_icd.json
wget -q https://raw.githubusercontent.com/haosulab/ManiSkill/main/docker/10_nvidia.json
mv nvidia_icd.json /usr/share/vulkan/icd.d
mv 10_nvidia.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json
apt-get install -y --no-install-recommends libvulkan-dev

# Install Python dependencies
pip install --upgrade mani_skill tyro
```

```python
# Detect Colab and refresh site-packages so local pip installs are recognised
try:
    import google.colab
    IN_COLAB = True
except ImportError:
    IN_COLAB = False

if IN_COLAB:
    import site
    site.main()
```

---

## 1  Running the Environments (CPU / GPU)

ManiSkill follows the [OpenAI Gym / Gymnasium API](https://gymnasium.farama.org/), making it compatible with a wide range of RL libraries. Tasks can be built in a flexible, pythonic way — see the [custom tasks tutorial](https://maniskill.readthedocs.io/en/latest/user_guide/tutorials/custom_tasks/intro.html) for details.

### 1.1  CPU Simulation

During CPU simulation the Gymnasium API is followed in full. The example below runs the **PegInsertionSide-v1** environment.  
A complete list of built-in environments is available at <https://maniskill.readthedocs.io/en/latest/tasks/index.html>.

```python
import gymnasium as gym
import mani_skill.envs
import time

env = gym.make("PegInsertionSide-v1")
obs, _ = env.reset(seed=0)
env.unwrapped.print_sim_details()   # verbose configuration summary

done = False
start_time = time.time()
while not done:
    obs, rew, terminated, truncated, info = env.step(env.action_space.sample())
    done = terminated or truncated

N   = info["elapsed_steps"].item()
dt  = time.time() - start_time
FPS = N / dt
print(f"Frames Per Second = {N} / {dt:.4f} = {FPS:.2f}")
```

**Sample output**

```
# -------------------------------------------------------------------------- #
Task ID: PegInsertionSide-v1, 1 parallel environments, sim_backend=physx_cpu
obs_mode=state, control_mode=pd_joint_delta_pos
render_mode=None, sensor_details=RGBD(128x128), RGBD(128x128)
sim_freq=100, control_freq=20
observation space: Box(-inf, inf, (1, 43), float32)
(single) action space: Box(-1.0, 1.0, (8,), float32)
# -------------------------------------------------------------------------- #
Frames Per Second = 100 / 1.8200 = 54.95
```

> **Note:** All data returned by ManiSkill is a **batched `torch.Tensor`**.  
> To obtain the standard Gymnasium behaviour (unbatched NumPy arrays) use `CPUGymWrapper`:

```python
from mani_skill.utils.wrappers import CPUGymWrapper

env = gym.make("PegInsertionSide-v1")
env = CPUGymWrapper(env)
obs, _ = env.reset()          # obs is a plain numpy array, shape (43,)
print(type(obs), obs.shape)
```

### 1.2  Rendering

| `render_mode`  | Behaviour |
|----------------|-----------|
| `"rgb_array"`  | Returns a batched RGB tensor — use `[0].cpu().numpy()` to view with matplotlib. |
| `"sensors"`    | Returns the actual visual data that the agent would receive in a visual observation mode. |
| `"all"`        | Combines `"rgb_array"` and `"sensors"`. |
| `"human"`      | Opens a GUI viewer (requires a display). |

```python
import matplotlib.pyplot as plt

env = gym.make("PegInsertionSide-v1", render_mode="rgb_array")
env.reset()
plt.imshow(env.render()[0].cpu().numpy())
plt.show()
```

---

## 2  GPU Simulation

ManiSkill supports massively-parallel GPU simulation. The API is largely identical to CPU simulation, but `num_envs` controls how many environments run in parallel.

```python
import gymnasium as gym
import mani_skill.envs
import time
import torch

num_envs = 1024  # number of parallel environments

env = gym.make(
    "PegInsertionSide-v1",
    num_envs=num_envs,
    obs_mode="state",
    control_mode="pd_joint_delta_pos",
    sim_backend="gpu",          # use the GPU physics backend
)
obs, _ = env.reset(seed=0)
env.unwrapped.print_sim_details()

done = torch.zeros(num_envs, dtype=torch.bool, device="cuda")
start_time = time.time()
while not done.all():
    obs, rew, terminated, truncated, info = env.step(env.action_space.sample())
    done = terminated | truncated

N   = info["elapsed_steps"][0].item()
dt  = time.time() - start_time
print(f"Effective FPS (across {num_envs} envs) = {N * num_envs / dt:.0f}")
```

> The physics backend is **physx_gpu** when `sim_backend="gpu"` is set.  
> Observations are batched tensors of shape `(num_envs, obs_dim)`.

---

## 3  Recording and Replaying Episodes

ManiSkill provides a `RecordEpisode` wrapper to save trajectories and render videos.

```python
from mani_skill.utils.wrappers import RecordEpisode
from IPython.display import Video
from tqdm.notebook import tqdm

env = gym.make(
    "PegInsertionSide-v1",
    obs_mode="state",
    control_mode="pd_joint_delta_pos",
    render_mode="rgb_array",
)
env = RecordEpisode(env, "./videos", save_trajectory=False)

obs, _ = env.reset()
for _ in tqdm(range(100)):
    obs, rew, terminated, truncated, info = env.step(env.action_space.sample())
    if terminated or truncated:
        obs, _ = env.reset()

env.flush_video("episode_demo")
Video("./videos/episode_demo.mp4", embed=True, width=640)
```

---

## 4  Teleoperation

ManiSkill supports interactive teleoperation through a GUI viewer. Keyboard and mouse inputs can be used to control the robot end-effector.

```python
import gymnasium as gym
import mani_skill.envs

env = gym.make(
    "PegInsertionSide-v1",
    obs_mode="state",
    control_mode="pd_ee_delta_pos",   # end-effector delta position control
    render_mode="human",               # opens the GUI viewer
)
env.reset()

# The GUI viewer allows keyboard / mouse teleoperation.
# Press 'q' to quit.
obs, _ = env.reset()
done = False
while not done:
    action = env.action_space.sample()   # replace with human input handler
    obs, rew, terminated, truncated, info = env.step(action)
    env.render()
    done = terminated or truncated

env.close()
```

---

## 5  More Robots

ManiSkill ships with a large number of pre-tuned robots. A full gallery is available at  
<https://maniskill.readthedocs.io/en/latest/robots/index.html>.

Robot **keyframes** (borrowed from MuJoCo) allow quick visualisation of canonical poses.

### 5.1  Download and visualise ANYmal-C

```python
# Download robot assets
!python -m mani_skill.utils.download_asset -y "anymal_c"
```

```python
import gymnasium as gym
import sapien
import mani_skill.envs
from tqdm.notebook import tqdm
from mani_skill.utils.wrappers import RecordEpisode
from IPython.display import Video

env = gym.make(
    "Empty-v1",
    obs_mode="none",
    reward_mode="none",
    enable_shadow=True,
    control_mode="pd_joint_pos",   # hold joints in place
    robot_uids="anymal_c",
    render_mode="rgb_array",
)

# NOTE: access the underlying env before wrapping to use .agent
base_env = env.unwrapped
kf = base_env.agent.keyframes["standing"]

env = RecordEpisode(env, "./videos", save_trajectory=False)
env.reset()

base_env.agent.robot.set_pose(kf.pose)
base_env.agent.robot.set_qpos(kf.qpos)

# Sync GPU state buffers if running GPU sim
if base_env.gpu_sim_enabled:
    base_env.scene._gpu_apply_all()
    base_env.scene.px.gpu_update_articulation_kinematics()
    base_env.scene._gpu_fetch_all()

env.render()
for _ in tqdm(range(20)):
    obs, reward, terminated, truncated, info = env.step(kf.qpos)

env.flush_video("anymal_standing")
Video("./videos/anymal_standing.mp4", embed=True, width=640)
```

### 5.2  Drop the robot from height

```python
env.reset()
base_env.agent.robot.set_pose(sapien.Pose([0, 0, 1]))  # 1 m above ground
base_env.agent.robot.set_qpos(kf.qpos)

if base_env.gpu_sim_enabled:
    base_env.scene._gpu_apply_all()
    base_env.scene.px.gpu_update_articulation_kinematics()
    base_env.scene._gpu_fetch_all()

env.render()
for _ in tqdm(range(60)):
    obs, reward, terminated, truncated, info = env.step(kf.qpos)

env.flush_video("anymal_drop")
Video("./videos/anymal_drop.mp4", embed=True, width=640)
```

### 5.3  List all registered robots

```python
from mani_skill.agents.registration import REGISTERED_AGENTS

print(list(REGISTERED_AGENTS.keys()))
```

**Registered robots (as of ManiSkill 3.0.1)**

```
allegro_hand_right, allegro_hand_left, allegro_hand_right_touch,
anymal_c, dclaw, fetch, floating_ability_hand_right,
floating_panda_gripper, floating_robotiq_2f_85_gripper,
googlerobot, humanoid, floating_inspire_hand_right,
floating_inspire_hand_left, fixed_inspire_hand_right,
fixed_inspire_hand_left, koch-v1.1, panda, panda_wristcam,
panda_stick, so100, stompy, trifingerpro, unitree_g1,
unitree_g1_simplified_legs, unitree_g1_simplified_upper_body,
unitree_g1_simplified_upper_body_with_head_camera,
unitree_g1_simplified_upper_body_right_arm, unitree_go2,
unitree_go2_simplified_locomotion, unitree_h1,
unitree_h1_simplified, ur_10e, widowx250s, widowxai,
widowxai_wristcam, xarm7_ability, xarm6_nogripper,
xarm6_nogripper_wristcam, xarm6_robotiq, xarm6_robotiq_wristcam,
xlerobot, widowx250s_bridgedataset_flat_table,
widowx250s_bridgedataset_sink
```

---

## 6  Motion Planning Solutions

Motion planning lets you define goal keypoints and compute a trajectory that reaches them. ManiSkill integrates with [MPLib](https://github.com/haosulab/MPlib) for lightweight motion planning.

The example below uses the pre-built motion planning solution for **PegInsertionSide-v1** with the **Panda arm**.  
Full solution code: <https://github.com/haosulab/ManiSkill/tree/main/mani_skill/examples/motionplanning/panda/solutions>

```python
from IPython.display import Video
```

```bash
python -m mani_skill.examples.motionplanning.panda.run \
    -e "PegInsertionSide-v1" \
    -n=1 \
    --save-video \
    --record-dir="demos" \
    --traj-name="peginsertionside" \
    --only-count-success
```

```python
Video("./demos/PegInsertionSide-v1/motionplanning/0.mp4", embed=True, width=640)
```

**Expected output**

```
Motion Planning Running on PegInsertionSide-v1
proc_id: 0: 100% 1/1 [completed]
```

---

## Key API Reference

| Symbol | Description |
|--------|-------------|
| `gym.make(task_id, **kwargs)` | Instantiate an environment. Key kwargs: `num_envs`, `obs_mode`, `control_mode`, `render_mode`, `robot_uids`, `sim_backend`. |
| `env.reset(seed=...)` | Reset environment; returns `(obs, info)`. |
| `env.step(action)` | Step environment; returns `(obs, reward, terminated, truncated, info)`. |
| `env.render()` | Render the current frame according to `render_mode`. |
| `env.unwrapped.print_sim_details()` | Print verbose simulation configuration. |
| `CPUGymWrapper(env)` | Wraps env so observations are unbatched NumPy arrays. |
| `RecordEpisode(env, path, ...)` | Saves trajectory / video to disk. |
| `env.agent.keyframes` | Dict of named robot poses (e.g. `"standing"`). |
| `env.gpu_sim_enabled` | `True` when the GPU physics backend is active. |

---

## Dependencies

| Package | Version used |
|---------|-------------|
| `mani_skill` | 3.0.1 |
| `sapien` | 3.0.3 |
| `mplib` | 0.1.1 |
| `pytorch_kinematics` | 0.7.6 |
| `torch` | 2.10.0+cu128 |
| `gymnasium` | ≥ 0.29.1 |
| `numpy` | ≥ 1.22 |
| `toppra` | 0.6.3 |
| `trimesh` | 4.12.2 |
| `transforms3d` | 0.4.2 |

> For local installation instructions see the [ManiSkill installation docs](https://maniskill.readthedocs.io/en/latest/user_guide/getting_started/installation.html).
