const anehPlayer = videojs('aneh-player'); // Initialize the Video.js player

// Function to load the last watched episode from localStorage
function loadLastWatched() {
    const lastWatched = localStorage.getItem('lastWatchedEpisode');
    if (lastWatched) {
        changeVideo(lastWatched, null); // Load the video without playing
    }
}

// Function to change the video and update the button state
function changeVideo(url, button) {
    anehPlayer.src({ type: 'video/mp4', src: url }); // Set the new video source

    // Save the last watched episode in localStorage
    localStorage.setItem('lastWatchedEpisode', url);

    // Change button color and disable it
    const buttons = document.querySelectorAll('.aneh-button');
    buttons.forEach(btn => {
        btn.classList.remove('active'); // Remove active class from all buttons
        btn.disabled = false; // Enable all buttons
    });

    if (button) {
        button.classList.add('active'); // Add active class to the clicked button
        button.disabled = true; // Disable the clicked button
    }
}

// Load the last watched episode when the page is loaded
window.onload = function() {
    loadLastWatched();

    // Highlight the active button
    const lastWatched = localStorage.getItem('lastWatchedEpisode');
    if (lastWatched) {
        const buttons = document.querySelectorAll('.aneh-button');
        buttons.forEach(btn => {
            if (btn.onclick.toString().includes(lastWatched)) {
                btn.classList.add('active');
                btn.disabled = true; // Disable the button
            }
        });
    }
};
