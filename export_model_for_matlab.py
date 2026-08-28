"""
Export trained PyTorch ResNet-18 weights into MATLAB .mat format and ONNX format
"""

import os
import torch
import torchvision.models as models
import scipy.io as sio

root_dir = os.path.dirname(os.path.abspath(__file__))
model_pth = os.path.join(root_dir, "models", "EyeXpert_ResNet18_best.pth")
onnx_out = os.path.join(root_dir, "models", "drModel.onnx")
mat_out = os.path.join(root_dir, "model", "drModel.mat")

os.makedirs(os.path.dirname(mat_out), exist_ok=True)

device = torch.device('cpu')
model = models.resnet18(weights=None)
model.fc = torch.nn.Linear(model.fc.in_features, 5)

ckpt = torch.load(model_pth, map_location=device, weights_only=False)
if 'model_state_dict' in ckpt:
    state_dict = ckpt['model_state_dict']
else:
    state_dict = ckpt

model.load_state_dict(state_dict)
model.eval()

# 1. Export ONNX (optional)
try:
    dummy_input = torch.randn(1, 3, 224, 224)
    torch.onnx.export(
        model, dummy_input, onnx_out,
        input_names=['input_fundus'],
        output_names=['class_logits'],
        opset_version=12
    )
    print(f"Exported ONNX model to: {onnx_out}")
except Exception as e:
    print(f"ONNX export skipped ({e}). Proceeding with direct MATLAB .mat weights export.")

# 2. Export MATLAB .mat dictionary with standard length keys
weights_list = []
names_list = []
for k, v in state_dict.items():
    names_list.append(k)
    weights_list.append(v.numpy())

mat_data = {
    'architecture': 'ResNet18',
    'numClasses': 5,
    'classNames': ['Level 0', 'Level 1', 'Level 2', 'Level 3', 'Level 4'],
    'inputSize': [224, 224, 3],
    'accuracy': 76.87,
    'qwk': 0.870,
    'referableSensitivity': 82.14,
    'referableSpecificity': 96.62,
    'referableAUC': 0.980,
    'layerNames': names_list,
    'layerWeights': weights_list
}
sio.savemat(mat_out, mat_data)
print(f"Exported MATLAB model artifact to: {mat_out}")
