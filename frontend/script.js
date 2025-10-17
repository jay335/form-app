document.getElementById('contactForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('name').value;
    const email = document.getElementById('email').value;

    try {
        const response = await fetch('http://form-app-backend-alb-858802151.us-east-1.elb.amazonaws.com/api/submit', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ name, email })
        });

        const result = await response.json();
        document.getElementById('message').textContent = result.message;
        document.getElementById('contactForm').reset();
    } catch (error) {
        document.getElementById('message').textContent = 'Error: ' + error.message;
    }
});

