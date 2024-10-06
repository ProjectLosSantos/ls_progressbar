const App = Vue.createApp({
    data() {
        return {
            show:false,
            label: 'Example Progress Text',
            icon: '',
            duration: 0,   
            progressPercentage: 0, 
            interval: null, 
        }
    },
    methods: {
        onMessage(event) {
            if (event.data.type === "startProgress") {
                this.label = event.data.table.label || 'No text defined'
                this.icon = event.data.table.icon || ''
                this.duration = event.data.table.duration || 5000

                this.progressPercentage = 0; 
                this.show = true
            } else if (event.data.type === 'cancelProgress') {
                this.progressPercentage = 99
                this.show = false
            }
        },
        startProgress() {
            const totalTime = this.duration; 
            const intervalTime = 100; 

            let elapsedTime = 0;

            if (this.interval) {
                clearInterval(this.interval);
            }

            this.interval = setInterval(() => {
                elapsedTime += intervalTime;
                this.progressPercentage = (elapsedTime / totalTime) * 100;

                if (this.progressPercentage >= 100) {
                    clearInterval(this.interval);
                    this.show = false
                    this.sendCompletionMessage()
                }
            }, intervalTime);
        },
        async sendCompletionMessage() {
                const response = await fetch(`https://${GetParentResourceName()}/progressEnded`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify()
                });

                const data = await response.json();
        }

    },
    async mounted() {
        window.addEventListener('message', this.onMessage);
    }
}).mount('#app');
