<script setup>
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

onMounted(() => {
  // Redirect to flows list by default
  router.replace({ name: 'builder_flows' });
});
</script>

<template>
  <div class="builder-index">
    <spinner size="" />
  </div>
</template>

<style scoped lang="scss">
.builder-index {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 400px;
}
</style>
