
    // JavaScript to handle modal and search functionality

    const blogId = '3416815958421967754';
const apiKey = 'AIzaSyBeCCkX4EjbFdOucsDjmTmeKEsIvhayF6g';
    const posts = [];

    // Function to extract the first image from post content if no image is provided
    function extractThumbnail(content) {
        const div = document.createElement('div');
        div.innerHTML = content;
        const img = div.querySelector('img');
        return img ? img.src : 'https://via.placeholder.com/150'; // Fallback placeholder image
    }

    // Function to fetch posts from the Blogger API
    function fetchPosts() {
        fetch(`https://www.googleapis.com/blogger/v3/blogs/${blogId}/posts?key=${apiKey}&fields=items(title,url,images,content)`)
            .then(response => response.json())
            .then(data => {
                if (data.items) {
                    data.items.forEach(post => {
                        posts.push({
                            title: post.title,
                            url: post.url,
                            thumbnail: post.images && post.images.length > 0 ? post.images[0].url : extractThumbnail(post.content)
                        });
                    });
                    console.log('Posts loaded:', posts);
                } else {
                    console.error('No posts found.');
                }
            })
            .catch(error => console.error('Error fetching posts:', error));
    }

    // Call fetchPosts on page load
    window.onload = fetchPosts;

    // Modal handling
    const modal = document.getElementById("searchModal");
    const btn = document.getElementById("openModal");
    const span = document.getElementsByClassName("close")[0];
    const searchButton = document.getElementById("searchButton");
    const searchResults = document.getElementById("search-results");

    // Open the modal
    btn.onclick = function() {
        modal.style.display = "block";
        searchResults.innerHTML = ''; // Clear previous results
    }

    // Close the modal
    span.onclick = function() {
        modal.style.display = "none";
    }

    // Close the modal when clicking outside of it
    window.onclick = function(event) {
        if (event.target == modal) {
            modal.style.display = "none";
        }
    }

    // Search function
    searchButton.onclick = function() {
        const query = document.getElementById("searchQuery").value;
        searchPosts(query);
    }

    function searchPosts(query) {
        const lowerQuery = query.toLowerCase();
        const results = posts.filter(post => post.title.toLowerCase().includes(lowerQuery));

        // Display the results
        searchResults.innerHTML = ''; // Clear previous results

        if (results.length > 0) {
            results.forEach((post, index) => {
                let resultItem = document.createElement('div');

                let thumbnail = document.createElement('img');
                thumbnail.src = post.thumbnail;

                let titleLink = document.createElement('a');
                titleLink.href = post.url;
                titleLink.textContent = post.title;

                resultItem.appendChild(thumbnail);
                resultItem.appendChild(titleLink);
                searchResults.appendChild(resultItem);

                // Add a separator line after each post except the last one
                if (index < results.length - 1) {
                    let separator = document.createElement('hr');
                    searchResults.appendChild(separator);
                }
            });
        } else {
            searchResults.innerHTML = '<p>No results found</p>';
        }
    }
