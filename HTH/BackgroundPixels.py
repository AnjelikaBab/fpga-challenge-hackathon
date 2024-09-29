import cv2
import numpy as np

# Load the image
image = cv2.imread('hackathonbckgrnd.jpg')

# Convert the image to YCrCb color space
ycrcb_image = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)

# Save the YCrCb pixel data to a file (optional, for use in your Verilog code)
np.savetxt('ycrcb_image_data.txt', ycrcb_image.reshape(-1, 3), fmt='%d')

# Display the YCrCb image (just for visualization, not necessary for Verilog)
cv2.imshow('YCrCb Image', ycrcb_image)
cv2.waitKey(0)
cv2.destroyAllWindows()
