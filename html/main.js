window.addEventListener('message', (event) => {
  const data = event.data
  const rz = document.querySelector('.rz-container')

  if (data.action === 'showUI') {
    rz.classList.remove('slide-out-left','slide-out-right','slide-out-top','hidden')
    
    // Determine from left, right, or top
    if (rz.classList.contains('bottom-left') || rz.classList.contains('top-left') || rz.classList.contains('center-left')) {
      rz.classList.remove('slide-in-right','slide-in-top')
      rz.classList.add('slide-in-left')
    }
    else if (rz.classList.contains('bottom-right') || rz.classList.contains('top-right') || rz.classList.contains('center-right')) {
      rz.classList.remove('slide-in-left','slide-in-top')
      rz.classList.add('slide-in-right')
    }
    else if (rz.classList.contains('center-top')) {
      rz.classList.remove('slide-in-left','slide-in-right')
      rz.classList.add('slide-in-top')
    }
  }
  else if (data.action === 'hideUI') {
    // Remove slide-in
    rz.classList.remove('slide-in-left','slide-in-right','slide-in-top')
    
    // Determine appropriate slide-out
    if (rz.classList.contains('bottom-left') || rz.classList.contains('top-left') || rz.classList.contains('center-left')) {
      rz.classList.add('slide-out-left')
    }
    else if (rz.classList.contains('bottom-right') || rz.classList.contains('top-right') || rz.classList.contains('center-right')) {
      rz.classList.add('slide-out-right')
    }
    else if (rz.classList.contains('center-top')) {
      rz.classList.add('slide-out-top')
    }

    rz.addEventListener('animationend', function onEnd(e) {
      if (e.animationName.includes('slideOut')) rz.classList.add('hidden')
      rz.removeEventListener('animationend', onEnd)
    })
  }
  else if (data.action === 'resetUI') {
    document.getElementById('killsValue').textContent = data.kills || 0
    document.getElementById('headshotsValue').textContent = data.headshots || 0
    document.getElementById('rewardsValue').textContent = '$' + (data.reward || 0)
  }
  else if (data.action === 'updateUI') {
    if (data.kills !== undefined) document.getElementById('killsValue').textContent = data.kills
    if (data.headshots !== undefined) document.getElementById('headshotsValue').textContent = data.headshots
    if (data.reward !== undefined) document.getElementById('rewardsValue').textContent = '$' + data.reward
  }
  else if (data.action === 'setUIPosition') {
    rz.classList.remove('bottom-left','bottom-right','top-left','top-right','center-left','center-right','center-top')
    rz.classList.add(data.position || 'bottom-left')
  }
})
