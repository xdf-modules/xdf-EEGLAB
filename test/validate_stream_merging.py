import pyxdf
import numpy as np
import scipy.io

# Load the XDF file
file_path = '/System/Volumes/Data/data/contracting/child_mind/data_pilot2/sub-P2222_ses-S001_task-CUNY_face_run-001_mobi.xdf'  # Replace with your XDF file path
streams, fileheader = pyxdf.load_xdf(file_path)

# Identify two continuous streams
stream1 = next(s for s in streams if s['info']['name'][0] == 'EGI NetAmp 0')
stream2 = next(s for s in streams if s['info']['name'][0] == 'Tobii')

# Extract data and timestamps
data1 = np.array(stream1['time_series'])
timestamps1 = np.array(stream1['time_stamps'])

data2 = np.array(stream2['time_series'])
timestamps2 = np.array(stream2['time_stamps'])

# Ensure the two streams have the same timestamps
# Interpolate data2 to match timestamps1
data2_interpolated = np.array([
    np.interp(timestamps1, timestamps2, data2[:, c]) for c in range(data2.shape[1])
]).T

# Concatenate the data
merged_data = np.hstack((data1, data2_interpolated))

# Save the merged data to a new MATLAB file
scipy.io.savemat('merged_data.mat', {'data': merged_data})